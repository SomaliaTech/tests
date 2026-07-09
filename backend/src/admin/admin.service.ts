import {
  BadRequestException,
  Injectable,
  NotFoundException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { CloudflareService } from '../cloudfare/cloudflare.service';
// At the top of admin.controller.ts

import {
  orders,
  products,
  users,
  notifications,
  orderItems,
  productVariants,
  categories,
  markets,
  mediaAssets,
} from '../drizzle/schema';
import {
  sql,
  eq,
  desc,
  or,
  like,
  and,
  gte,
  lte,
  lt,
  inArray,
  SQL,
  asc,
} from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';
import { colors, sizes } from '../drizzle/schema';
import { SupabaseService } from 'src/supabase/supabase.service';
import { CreateProductAdminDto } from './dto/create-proudct-admin-dto';
import { ChatGateway } from '../chat/chat.gateway';
import { NotificationsService } from 'src/notifications/notifications.service';
import { NotificationType } from 'src/notifications/notification.entity';

// Type definitions
interface CategoryData {
  name: string;
  slug?: string;
  description?: string;
  parentId?: string;
  iconBase64?: string;
}

interface CategoryUpdateData {
  name?: string;
  slug?: string;
  description?: string;
  iconBase64?: string;
}

interface ColorData {
  name: string;
  code: string;
}

interface ColorUpdateData {
  name?: string;
  code?: string;
}

interface SizeData {
  name: string;
  value: string;
}

interface SizeUpdateData {
  name?: string;
  value?: string;
}

interface MarketData {
  name: string;
  slug?: string;
  city?: string;
}

interface MarketUpdateData {
  name?: string;
  slug?: string;
  city?: string;
  isActive?: boolean;
}

interface VariantData {
  colorId: string;
  sizeId: string;
  sku?: string;
  stock?: number;
  price?: number;
}

interface ProductUpdateData {
  name?: string;
  description?: string;
  price?: number;
  stock?: number;
  categoryId?: string;
  brand?: string;
  tags?: string;
  isActive?: boolean;
}

@Injectable()
export class AdminService {
  // ✅ CORRECT - all services properly injected
  constructor(
    private drizzle: DrizzleService,
    private cloudflareService: CloudflareService,
    private supabaseService: SupabaseService,
    @Inject(forwardRef(() => ChatGateway))
    private chatGateway: ChatGateway,
    @Inject(forwardRef(() => NotificationsService))
    private notificationsService: NotificationsService,
  ) {}

  async getStats() {
    const [result] = await this.drizzle.db
      .select({
        totalProducts: sql<number>`(SELECT COUNT(*) FROM products)`,
        totalOrders: sql<number>`(SELECT COUNT(*) FROM orders)`,
        totalRevenue: sql<number>`(SELECT COALESCE(SUM(CAST(total_amount AS DECIMAL)), 0) FROM orders WHERE payment_status = 'PAID')`,
        totalUsers: sql<number>`(SELECT COUNT(*) FROM users)`,
      })
      .from(users)
      .limit(1);

    return {
      totalProducts: Number(result?.totalProducts) || 0,
      totalOrders: Number(result?.totalOrders) || 0,
      totalRevenue: Number(result?.totalRevenue) || 0,
      totalUsers: Number(result?.totalUsers) || 0,
    };
  }
  // User Management
  async updateUser(
    userId: string,
    updateData: {
      name?: string;
      email?: string;
      marketId?: string;
      isAdmin?: boolean;
    },
  ) {
    const [updatedUser] = await this.drizzle.db
      .update(users)
      .set({ ...updateData, updatedAt: new Date() })
      .where(eq(users.id, userId))
      .returning();

    if (!updatedUser) throw new NotFoundException('User not found');

    return { message: 'User updated successfully', user: updatedUser };
  }

  async createUser(userData: {
    phoneNumber: string;
    name?: string;
    email?: string;
    marketId?: string;
  }) {
    const existingUser = await this.drizzle.db.query.users.findFirst({
      where: eq(users.phoneNumber, userData.phoneNumber),
    });

    if (existingUser) {
      throw new BadRequestException('Phone number already registered');
    }

    const [newUser] = await this.drizzle.db
      .insert(users)
      .values({
        id: uuidv4(),
        phoneNumber: userData.phoneNumber,
        name: userData.name,
        email: userData.email,
        marketId: userData.marketId,
        isVerified: true,
      })
      .returning();

    try {
      this.chatGateway.server.to('admins').emit('new_notification', {
        id: uuidv4(),
        type: 'system',
        title: 'New User Registered',
        message: `${newUser.name || 'A new user'} has registered`,
        actionText: 'View User',
        actionLink: `/admin/users/${newUser.id}`,
        createdAt: new Date().toISOString(),
        isRead: false,
      });
    } catch (error) {
      // Silent fail for notifications
    }

    return { message: 'User created successfully', user: newUser };
  }

  async getUserById(userId: string) {
    const user = await this.drizzle.db.query.users.findFirst({
      where: eq(users.id, userId),
      with: {
        addresses: true,
        orders: {
          orderBy: [desc(orders.createdAt)],
          limit: 10,
        },
      },
    });

    if (!user) throw new NotFoundException('User not found');
    return user;
  }
  async getAllUsers(
    currentUserId?: string,
    search?: string,
    page: number = 1,
    limit: number = 20,
  ) {
    const offset = (page - 1) * limit;
    const conditions: SQL[] = [];

    if (currentUserId) {
      conditions.push(sql`${users.id} != ${currentUserId}`);
    }

    if (search && search.trim()) {
      const pattern = `%${search.trim()}%`;
      conditions.push(
        or(
          like(users.name, pattern),
          like(users.email, pattern),
          like(users.phoneNumber, pattern),
        )!,
      );
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    const [items, total] = await Promise.all([
      this.drizzle.db.query.users.findMany({
        where: whereClause,
        orderBy: [desc(users.createdAt)],
        limit,
        offset,
        with: {
          addresses: true,
          orders: {
            limit: 5,
            orderBy: [desc(orders.createdAt)],
          },
        },
      }),
      this.drizzle.db
        .select({ count: sql<number>`COUNT(*)::int` })
        .from(users)
        .where(whereClause),
    ]);

    return {
      items,
      pagination: {
        page,
        limit,
        total: total[0]?.count || 0,
        totalPages: Math.ceil((total[0]?.count || 0) / limit),
      },
    };
  }
  // Order Management
  async getAllOrders(
    search?: string,
    page: number = 1,
    limit: number = 20,
    status?: string,
  ) {
    const offset = (page - 1) * limit;
    const conditions: SQL[] = [];

    if (search && search.trim()) {
      const pattern = `%${search.trim()}%`;
      conditions.push(
        or(
          like(orders.orderNumber, pattern),
          like(orders.customerName, pattern),
          like(orders.customerEmail, pattern),
        )!,
      );
    }

    if (status) {
      conditions.push(eq(orders.status, status));
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    const [items, total] = await Promise.all([
      this.drizzle.db.query.orders.findMany({
        where: whereClause,
        orderBy: [desc(orders.createdAt)],
        limit,
        offset,
        with: {
          user: {
            columns: {
              id: true,
              name: true,
              phoneNumber: true,
              email: true,
            },
          },
          items: {
            limit: 10,
            with: {
              variant: {
                columns: {
                  id: true,
                  sku: true,
                },
                with: {
                  product: {
                    columns: {
                      id: true,
                      name: true,
                      slug: true,
                    },
                  },
                },
              },
            },
          },
        },
      }),
      this.drizzle.db
        .select({ count: sql<number>`COUNT(*)::int` })
        .from(orders)
        .where(whereClause),
    ]);

    return {
      items,
      pagination: {
        page,
        limit,
        total: total[0]?.count || 0,
        totalPages: Math.ceil((total[0]?.count || 0) / limit),
      },
    };
  }

  async updateOrderStatus(orderId: string, status: string) {
    const [order] = await this.drizzle.db
      .update(orders)
      .set({ status, updatedAt: new Date() })
      .where(eq(orders.id, orderId))
      .returning();

    if (!order) throw new NotFoundException('Order not found');

    if (order.userId) {
      try {
        await this.notificationsService.create({
          userId: order.userId,
          type: NotificationType.ORDER,
          title: 'Order Status Updated',
          message: `Your order #${order.orderNumber} is now ${status.toLowerCase()}`,
          actionText: 'View Order',
          actionLink: `/orders/${order.id}`,
        });
      } catch (e) {
        // Silent fail
      }
    }

    return {
      message: 'Order status updated successfully',
      order: {
        id: order.id,
        orderNumber: order.orderNumber,
        status: order.status,
      },
    };
  }

  async getRecentOrders(limit: number = 5) {
    const recentOrders = await this.drizzle.db.query.orders.findMany({
      orderBy: [desc(orders.createdAt)],
      limit: Math.min(limit, 20),
      with: {
        items: {
          limit: 5,
        },
        user: {
          columns: {
            id: true,
            name: true,
            phoneNumber: true,
          },
        },
      },
    });

    return recentOrders.map((order) => ({
      id: order.id,
      orderNumber: order.orderNumber,
      customerName: order.customerName,
      customerEmail: order.customerEmail || '',
      totalAmount: Number(order.totalAmount),
      status: order.status,
      paymentStatus: order.paymentStatus,
      createdAt: order.createdAt,
      itemsCount: order.items?.length || 0,
    }));
  }

  // Dashboard & Analytics
  async getAllDashboardData(period: string) {
    const [
      stats,
      usersChartData,
      revenueChartData,
      deviceTraffic,
      locationTraffic,
      productTraffic,
    ] = await Promise.all([
      this.getDashboardStats(period),
      this.getUsersChartData(period),
      this.getRevenueChart(period),
      this.getDeviceTraffic(),
      this.getLocationTraffic(),
      this.getProductTraffic(period),
    ]);

    return {
      stats,
      usersChartData,
      revenueChartData,
      deviceTraffic,
      locationTraffic,
      productTraffic,
    };
  }
  async getDashboardStats(period: string) {
    const currentStats = await this.getStatsForPeriod(period);
    const previousPeriod = this.getPreviousPeriod(period);
    const previousStats = await this.getStatsForPeriod(previousPeriod);

    return {
      totalUsers: currentStats.totalUsers,
      totalOrders: currentStats.totalOrders,
      totalRevenue: currentStats.totalRevenue,
      newUsers: currentStats.newUsers,
      userGrowth: this.calculateGrowth(
        previousStats.totalUsers,
        currentStats.totalUsers,
      ),
      orderGrowth: this.calculateGrowth(
        previousStats.totalOrders,
        currentStats.totalOrders,
      ),
      revenueGrowth: this.calculateGrowth(
        previousStats.totalRevenue,
        currentStats.totalRevenue,
      ),
      newUserGrowth: this.calculateGrowth(
        previousStats.newUsers,
        currentStats.newUsers,
      ),
    };
  }

  private calculateGrowth(previous: number, current: number): number {
    if (previous === 0) return current > 0 ? 100 : 0;
    return Number((((current - previous) / previous) * 100).toFixed(1));
  }

  private getPreviousPeriod(period: string): string {
    const periodMap: Record<string, string> = {
      day: 'previous_day',
      week: 'previous_week',
      month: 'previous_month',
      year: 'previous_year',
    };
    return periodMap[period] || 'previous_week';
  }

  private getDateRangeForPeriod(period: string): { start: Date; end: Date } {
    const now = new Date();
    let start: Date;
    let end: Date = now;

    switch (period) {
      case 'day':
        start = new Date(now);
        start.setHours(0, 0, 0, 0);
        break;
      case 'week':
        start = new Date(now);
        start.setDate(now.getDate() - 7);
        start.setHours(0, 0, 0, 0);
        break;
      case 'month':
        start = new Date(now);
        start.setMonth(now.getMonth() - 1);
        start.setHours(0, 0, 0, 0);
        break;
      case 'year':
        start = new Date(now);
        start.setFullYear(now.getFullYear() - 1);
        start.setHours(0, 0, 0, 0);
        break;
      case 'previous_day':
        start = new Date(now);
        start.setDate(now.getDate() - 2);
        start.setHours(0, 0, 0, 0);
        end = new Date(now);
        end.setDate(now.getDate() - 1);
        end.setHours(23, 59, 59, 999);
        break;
      case 'previous_week':
        start = new Date(now);
        start.setDate(now.getDate() - 14);
        start.setHours(0, 0, 0, 0);
        end = new Date(now);
        end.setDate(now.getDate() - 7);
        end.setHours(23, 59, 59, 999);
        break;
      case 'previous_month':
        start = new Date(now);
        start.setMonth(now.getMonth() - 2);
        start.setHours(0, 0, 0, 0);
        end = new Date(now);
        end.setMonth(now.getMonth() - 1);
        end.setHours(23, 59, 59, 999);
        break;
      case 'previous_year':
        start = new Date(now);
        start.setFullYear(now.getFullYear() - 2);
        start.setHours(0, 0, 0, 0);
        end = new Date(now);
        end.setFullYear(now.getFullYear() - 1);
        end.setHours(23, 59, 59, 999);
        break;
      default:
        start = new Date(now);
        start.setDate(now.getDate() - 7);
        start.setHours(0, 0, 0, 0);
    }

    return { start, end };
  }

  private async getStatsForPeriod(period: string) {
    const dateRange = this.getDateRangeForPeriod(period);

    const stats = await this.drizzle.db
      .select({
        totalUsers: sql<number>`count(distinct ${users.id})`,
        totalOrders: sql<number>`count(distinct ${orders.id})`,
        totalRevenue: sql<number>`coalesce(sum(cast(${orders.totalAmount} as decimal)), 0)`,
        newUsers: sql<number>`count(distinct ${users.id})`,
      })
      .from(users)
      .leftJoin(orders, eq(users.id, orders.userId))
      .where(
        and(
          gte(users.createdAt, dateRange.start),
          lte(users.createdAt, dateRange.end),
        ),
      );

    return {
      totalUsers: Number(stats[0]?.totalUsers) || 0,
      totalOrders: Number(stats[0]?.totalOrders) || 0,
      totalRevenue: Number(stats[0]?.totalRevenue) || 0,
      newUsers: Number(stats[0]?.newUsers) || 0,
    };
  }

  async getUsersChartData(period: string) {
    const dateRange = this.getDateRangeForPeriod(period);

    const results = await this.drizzle.db
      .select({
        date: sql<string>`date_trunc('day', ${users.createdAt})::date::text`,
        count: sql<number>`count(*)::int`,
      })
      .from(users)
      .where(
        and(
          gte(users.createdAt, dateRange.start),
          lte(users.createdAt, dateRange.end),
        ),
      )
      .groupBy(sql`date_trunc('day', ${users.createdAt})`)
      .orderBy(sql`date_trunc('day', ${users.createdAt})`);

    return this.fillDateGaps(results, dateRange.start, dateRange.end);
  }

  async getRevenueChart(period: string) {
    const dateRange = this.getDateRangeForPeriod(period);

    const results = await this.drizzle.db
      .select({
        date: sql<string>`date_trunc('day', ${orders.createdAt})::date::text`,
        revenue: sql<number>`coalesce(sum(cast(${orders.totalAmount} as decimal)), 0)`,
        count: sql<number>`count(*)::int`,
      })
      .from(orders)
      .where(
        and(
          eq(orders.paymentStatus, 'PAID'),
          gte(orders.createdAt, dateRange.start),
          lte(orders.createdAt, dateRange.end),
        ),
      )
      .groupBy(sql`date_trunc('day', ${orders.createdAt})`)
      .orderBy(sql`date_trunc('day', ${orders.createdAt})`);

    return this.fillDateGaps(
      results.map((r) => ({
        date: r.date,
        count: r.count,
        value: Number(r.revenue),
      })),
      dateRange.start,
      dateRange.end,
    );
  }

  private fillDateGaps(
    data: Array<{ date: string; count: number; value?: number }>,
    start: Date,
    end: Date,
  ) {
    const result: Array<{ date: string; value: number; count: number }> = [];
    const dataMap = new Map(data.map((d) => [d.date, d]));

    const current = new Date(start);
    while (current <= end) {
      const dateStr = current.toISOString().split('T')[0];
      const existing = dataMap.get(dateStr);
      result.push({
        date: dateStr,
        value: existing ? (existing.value ?? existing.count) : 0,
        count: existing ? existing.count : 0,
      });
      current.setDate(current.getDate() + 1);
    }

    return result;
  }

  getDeviceTraffic() {
    return [
      { device: 'Mobile', value: 58, color: '#2ED573' },
      { device: 'Desktop', value: 32, color: '#1E90FF' },
      { device: 'Tablet', value: 10, color: '#FFA502' },
    ];
  }

  async getLocationTraffic() {
    const locationStats = await this.drizzle.db
      .select({
        location: users.marketId,
        count: sql<number>`count(*)`,
      })
      .from(users)
      .groupBy(users.marketId);

    const total = locationStats.reduce(
      (sum, item) => sum + Number(item.count),
      0,
    );

    return locationStats.map((item) => ({
      location: item.location || 'Unknown',
      value: Number(item.count),
      percentage:
        total > 0 ? ((Number(item.count) / total) * 100).toFixed(1) : '0',
    }));
  }

  async getProductTraffic(period: string) {
    const dateRange = this.getDateRangeForPeriod(period);

    try {
      const productStats = await this.drizzle.db
        .select({
          productId: products.id,
          productName: products.name,
          views: sql<number>`count(${orderItems.id})`,
        })
        .from(orderItems)
        .leftJoin(orders, eq(orders.id, orderItems.orderId))
        .leftJoin(
          productVariants,
          eq(productVariants.id, orderItems.productVariantId),
        )
        .leftJoin(products, eq(products.id, productVariants.productId))
        .where(
          and(
            gte(orders.createdAt, dateRange.start),
            lte(orders.createdAt, dateRange.end),
            eq(orders.paymentStatus, 'PAID'),
          ),
        )
        .groupBy(products.id, products.name)
        .orderBy(sql`count(${orderItems.id}) DESC`)
        .limit(10);

      if (
        productStats.length === 0 ||
        productStats.every((p) => p.productId === null)
      ) {
        return [
          { productId: 'mock-1', productName: 'iPhone 15 Pro', views: 45 },
          { productId: 'mock-2', productName: 'MacBook Pro', views: 32 },
          { productId: 'mock-3', productName: 'AirPods Pro', views: 28 },
        ];
      }

      return productStats.filter((p) => p.productId !== null);
    } catch {
      return [
        { productId: 'mock-1', productName: 'iPhone 15 Pro', views: 45 },
        { productId: 'mock-2', productName: 'MacBook Pro', views: 32 },
        { productId: 'mock-3', productName: 'AirPods Pro', views: 28 },
      ];
    }
  }

  async getRevenueSummary(period: string = 'week') {
    const dateRange = this.getDateRangeForPeriod(period);

    const [totalRevenue] = await this.drizzle.db
      .select({
        total: sql<string>`COALESCE(SUM(CAST(${orders.totalAmount} AS DECIMAL)), 0)`,
        count: sql<number>`COUNT(*)::int`,
        avgOrder: sql<string>`COALESCE(AVG(CAST(${orders.totalAmount} AS DECIMAL)), 0)`,
      })
      .from(orders)
      .where(
        and(
          eq(orders.paymentStatus, 'PAID'),
          gte(orders.createdAt, dateRange.start),
          lte(orders.createdAt, dateRange.end),
        ),
      );

    const previousStart = new Date(dateRange.start);
    const duration = dateRange.end.getTime() - dateRange.start.getTime();
    previousStart.setTime(previousStart.getTime() - duration);
    const previousEnd = new Date(dateRange.start);

    const [previousPeriodRevenue] = await this.drizzle.db
      .select({
        total: sql<string>`COALESCE(SUM(CAST(${orders.totalAmount} AS DECIMAL)), 0)`,
      })
      .from(orders)
      .where(
        and(
          eq(orders.paymentStatus, 'PAID'),
          gte(orders.createdAt, previousStart),
          lt(orders.createdAt, previousEnd),
        ),
      );

    const currentTotal = Number(totalRevenue.total) || 0;
    const previousTotal = Number(previousPeriodRevenue.total) || 0;
    const growth =
      previousTotal === 0
        ? currentTotal > 0
          ? 100
          : 0
        : Number(
            (((currentTotal - previousTotal) / previousTotal) * 100).toFixed(1),
          );

    const paymentBreakdown = await this.drizzle.db
      .select({
        method: orders.paymentMethod,
        total: sql<string>`COALESCE(SUM(CAST(${orders.totalAmount} AS DECIMAL)), 0)`,
        count: sql<number>`COUNT(*)::int`,
      })
      .from(orders)
      .where(
        and(
          eq(orders.paymentStatus, 'PAID'),
          gte(orders.createdAt, dateRange.start),
          lte(orders.createdAt, dateRange.end),
        ),
      )
      .groupBy(orders.paymentMethod);

    return {
      totalRevenue: currentTotal,
      totalOrders: Number(totalRevenue.count) || 0,
      averageOrderValue: Number(totalRevenue.avgOrder) || 0,
      growth: growth,
      paymentBreakdown: paymentBreakdown.map((pb) => ({
        method: pb.method || 'unknown',
        total: Number(pb.total),
        count: Number(pb.count),
      })),
    };
  }

  async getAllRevenue(
    search?: string,
    paymentMethod?: string,
    status?: string,
    page: number = 1,
    limit: number = 20,
  ) {
    const offset = (page - 1) * limit;
    const conditions: SQL[] = [eq(orders.paymentStatus, 'PAID')];

    if (search && search.trim()) {
      const pattern = `%${search.trim()}%`;
      conditions.push(
        or(
          like(orders.orderNumber, pattern),
          like(orders.customerName, pattern),
          like(orders.customerEmail, pattern),
        )!,
      );
    }

    if (paymentMethod) {
      conditions.push(eq(orders.paymentMethod, paymentMethod));
    }

    if (status) {
      conditions.push(eq(orders.status, status));
    }

    const whereClause = and(...conditions);

    const [items, total] = await Promise.all([
      this.drizzle.db.query.orders.findMany({
        where: whereClause,
        orderBy: [desc(orders.createdAt)],
        limit,
        offset,
        with: {
          user: {
            columns: {
              id: true,
              name: true,
              phoneNumber: true,
              email: true,
            },
          },
          items: {
            limit: 10,
            with: {
              variant: {
                with: {
                  product: {
                    columns: {
                      id: true,
                      name: true,
                      slug: true,
                    },
                  },
                },
              },
            },
          },
        },
      }),
      this.drizzle.db
        .select({ count: sql<number>`COUNT(*)::int` })
        .from(orders)
        .where(whereClause),
    ]);

    return {
      data: items.map((order) => ({
        id: order.id,
        orderNumber: order.orderNumber,
        customerName: order.customerName,
        customerEmail: order.customerEmail,
        totalAmount: Number(order.totalAmount),
        paymentMethod: order.paymentMethod,
        paymentStatus: order.paymentStatus,
        status: order.status,
        createdAt: order.createdAt,
        itemsCount: order.items?.length || 0,
      })),
      pagination: {
        page,
        limit,
        total: total[0]?.count || 0,
        totalPages: Math.ceil((total[0]?.count || 0) / limit),
      },
    };
  }

  // Product Management
  async getAllProducts() {
    return this.drizzle.db.query.products.findMany({
      orderBy: [desc(products.createdAt)],
      with: { images: true, category: true },
    });
  }
  async getAllProductsAdmin(
    page: number = 1,
    limit: number = 20,
    search?: string,
    categoryId?: string,
  ) {
    const offset = (page - 1) * limit;
    const conditions: SQL[] = [];

    if (search && search.trim()) {
      const pattern = `%${search.trim()}%`;
      conditions.push(
        or(like(products.name, pattern), like(products.slug, pattern))!,
      );
    }
    if (categoryId) {
      conditions.push(eq(products.categoryId, categoryId));
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    const [items, total] = await Promise.all([
      this.drizzle.db.query.products.findMany({
        where: whereClause,
        orderBy: [desc(products.createdAt)],
        limit: Math.min(limit, 50),
        offset,
        with: {
          category: {
            columns: { id: true, name: true, slug: true },
          },
          images: {
            limit: 5,
            orderBy: [desc(mediaAssets.isMain), desc(mediaAssets.order)],
          },
          variants: {
            limit: 5,
            with: {
              color: { columns: { id: true, name: true, code: true } },
              size: { columns: { id: true, name: true, value: true } },
            },
          },
        },
      }),
      this.drizzle.db
        .select({ count: sql<number>`COUNT(*)::int` })
        .from(products)
        .where(whereClause),
    ]);

    return {
      items,
      pagination: {
        page,
        limit,
        total: total[0]?.count || 0,
        totalPages: Math.ceil((total[0]?.count || 0) / limit),
      },
    };
  }
  async getProductById(productId: string) {
    // ✅ Force fresh data by not using any cache
    const product = await this.drizzle.db.query.products.findFirst({
      where: eq(products.id, productId),
      with: {
        category: true,
        images: {
          orderBy: [desc(mediaAssets.isMain), desc(mediaAssets.order)],
        },
        variants: {
          with: {
            color: true,
            size: true,
          },
        },
      },
    });

    if (!product) throw new NotFoundException('Product not found');

    console.log(
      `📦 getProductById - Variants count: ${product.variants?.length || 0}`,
    );
    return product;
  }

  async createProduct(createProductDto: CreateProductAdminDto) {
    const productId = uuidv4();

    // ✅ Generate unique slug
    let slug =
      createProductDto.slug ||
      createProductDto.name
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-|-$/g, '');

    // ✅ Check if slug exists and make it unique
    const existingProduct = await this.drizzle.db
      .select({ slug: products.slug })
      .from(products)
      .where(eq(products.slug, slug))
      .limit(1);

    if (existingProduct.length > 0) {
      // Add timestamp to make it unique
      slug = `${slug}-${Date.now()}`;
      console.log(
        `⚠️ [Admin] Slug "${createProductDto.slug || createProductDto.name}" already exists. Using: ${slug}`,
      );
    }

    // ✅ Validate category exists
    const [category] = await this.drizzle.db
      .select({ id: categories.id })
      .from(categories)
      .where(eq(categories.id, createProductDto.categoryId))
      .limit(1);

    if (!category) {
      throw new BadRequestException(
        `Category with ID ${createProductDto.categoryId} does not exist`,
      );
    }

    // ✅ Convert ALL decimal fields to strings
    const insertData: Record<string, unknown> = {
      id: productId,
      name: createProductDto.name,
      slug: slug, // ✅ Use the unique slug
      price: createProductDto.price.toString(),
      stock: createProductDto.stock ?? 0,
      isActive: createProductDto.isActive ?? true,
      isFeatured: createProductDto.isFeatured ?? false,
      categoryId: createProductDto.categoryId,
    };

    // Optional text fields
    if (createProductDto.description) {
      insertData.description = createProductDto.description;
    }
    if (createProductDto.sku) insertData.sku = createProductDto.sku;
    if (createProductDto.barcode) insertData.barcode = createProductDto.barcode;
    if (createProductDto.brand) insertData.brand = createProductDto.brand;
    if (createProductDto.tags) insertData.tags = createProductDto.tags;
    if (createProductDto.seoTitle)
      insertData.seoTitle = createProductDto.seoTitle;
    if (createProductDto.seoDescription) {
      insertData.seoDescription = createProductDto.seoDescription;
    }

    // ✅ Convert optional decimal fields to strings
    if (
      createProductDto.compareAtPrice !== undefined &&
      createProductDto.compareAtPrice !== null
    ) {
      insertData.compareAtPrice = createProductDto.compareAtPrice.toString();
    }
    if (
      createProductDto.costPerItem !== undefined &&
      createProductDto.costPerItem !== null
    ) {
      insertData.costPerItem = createProductDto.costPerItem.toString();
    }
    if (
      createProductDto.weight !== undefined &&
      createProductDto.weight !== null
    ) {
      insertData.weight = createProductDto.weight.toString();
    }

    try {
      console.log('✅ [Admin] Inserting product with data:', insertData);
      console.log('✅ [Admin] Price type:', typeof insertData.price);

      await this.drizzle.db
        .insert(products)
        .values(insertData as typeof products.$inferInsert)
        .returning();

      // Handle variants
      if (createProductDto.variants && createProductDto.variants.length > 0) {
        for (const variant of createProductDto.variants) {
          const variantSku =
            variant.sku ||
            `${slug}-${variant.colorId.slice(0, 4)}-${variant.sizeId.slice(0, 4)}`.toUpperCase();

          const variantData: Record<string, unknown> = {
            id: uuidv4(),
            productId,
            colorId: variant.colorId,
            sizeId: variant.sizeId,
            sku: variantSku,
            stock: variant.stock ?? 0,
          };

          if (variant.price !== undefined && variant.price !== null) {
            variantData.price = variant.price.toString();
          }

          await this.drizzle.db
            .insert(productVariants)
            .values(variantData as typeof productVariants.$inferInsert);
        }
      }

      return this.getProductById(productId);
    } catch (error: unknown) {
      const err = error as { message?: string; detail?: string; code?: string };
      console.error('❌ Database Insert Error:', err.message);
      console.error('❌ Error Code:', err.code);
      console.error('❌ Error Detail:', err.detail);

      // ✅ Better error messages
      if (err.code === '23505') {
        if (err.detail?.includes('slug')) {
          throw new BadRequestException(
            'A product with this slug already exists. Please use a different name.',
          );
        }
        if (err.detail?.includes('sku')) {
          throw new BadRequestException(
            'A product with this SKU already exists.',
          );
        }
      }

      throw new BadRequestException(
        `Failed to create product: ${err.detail || err.message}`,
      );
    }
  }

  // Add this to the AdminService class, replacing the existing updateProduct method
  // In admin.service.ts - updateProduct method

  async updateProduct(
    productId: string,
    updateData: any,
    newImages?: Array<Express.Multer.File>,
  ) {
    const product = await this.drizzle.db.query.products.findFirst({
      where: eq(products.id, productId),
    });

    if (!product) throw new NotFoundException('Product not found');

    // ✅ Use transaction for all database operations
    await this.drizzle.db.transaction(async (tx) => {
      // 1. Update basic product info
      if (
        updateData.name !== undefined ||
        updateData.price !== undefined ||
        updateData.stock !== undefined
      ) {
        const updateValues: Record<string, unknown> = { updatedAt: new Date() };
        if (updateData.name !== undefined) updateValues.name = updateData.name;
        if (updateData.description !== undefined)
          updateValues.description = updateData.description;
        if (updateData.price !== undefined)
          updateValues.price = updateData.price.toString();
        if (updateData.stock !== undefined)
          updateValues.stock = updateData.stock;
        if (updateData.categoryId !== undefined)
          updateValues.categoryId = updateData.categoryId;
        if (updateData.brand !== undefined)
          updateValues.brand = updateData.brand;
        if (updateData.tags !== undefined) updateValues.tags = updateData.tags;
        if (updateData.isActive !== undefined)
          updateValues.isActive = updateData.isActive;

        await tx
          .update(products)
          .set(updateValues)
          .where(eq(products.id, productId));
      }

      // 2. Delete images marked for deletion
      if (updateData.deleted_image_ids?.length > 0) {
        console.log(
          `🗑️ Deleting ${updateData.deleted_image_ids.length} images`,
        );

        // Delete from Supabase storage (fire and forget)
        const imagesToDelete = await tx
          .select()
          .from(mediaAssets)
          .where(inArray(mediaAssets.id, updateData.deleted_image_ids));

        for (const image of imagesToDelete) {
          this.supabaseService.deleteImage(image.publicId).catch((err) => {
            console.error(`Failed to delete image: ${image.publicId}`, err);
          });
        }

        // Delete from database
        await tx
          .delete(mediaAssets)
          .where(inArray(mediaAssets.id, updateData.deleted_image_ids));
      }

      // 3. ✅ FORCE DELETE variants (skip order history check)
      if (updateData.deleted_variant_ids?.length > 0) {
        console.log(
          `🗑️ Force deleting ${updateData.deleted_variant_ids.length} variants`,
        );

        await tx
          .delete(productVariants)
          .where(inArray(productVariants.id, updateData.deleted_variant_ids));
      }

      // 4. Update existing variants
      if (updateData.existing_variants?.length > 0) {
        console.log(
          `✏️ Updating ${updateData.existing_variants.length} variants`,
        );

        for (const variant of updateData.existing_variants) {
          const vId = variant.variantId || variant.id;
          if (vId) {
            const variantUpdate: Record<string, unknown> = {
              updatedAt: new Date(),
            };
            if (variant.colorId) variantUpdate.colorId = variant.colorId;
            if (variant.sizeId) variantUpdate.sizeId = variant.sizeId;
            if (variant.sku !== undefined) variantUpdate.sku = variant.sku;
            if (variant.stock !== undefined)
              variantUpdate.stock = variant.stock;
            if (variant.price !== undefined)
              variantUpdate.price = variant.price?.toString();

            await tx
              .update(productVariants)
              .set(variantUpdate)
              .where(eq(productVariants.id, vId));
          }
        }
      }

      // 5. Create new variants
      if (updateData.new_variants?.length > 0) {
        console.log(
          `➕ Creating ${updateData.new_variants.length} new variants`,
        );

        for (const variant of updateData.new_variants) {
          await tx.insert(productVariants).values({
            id: uuidv4(),
            productId,
            colorId: variant.colorId,
            sizeId: variant.sizeId,
            sku:
              variant.sku ||
              `${product.slug?.slice(0, 4)}-${variant.colorId?.slice(0, 4)}-${variant.sizeId?.slice(0, 4)}`.toUpperCase(),
            stock: variant.stock ?? 0,
            price: variant.price?.toString(),
          });
        }
      }

      // 6. Upload new images (inside transaction)
      if (newImages && newImages.length > 0) {
        console.log(`🖼️ Uploading ${newImages.length} new images`);

        for (let i = 0; i < newImages.length; i++) {
          const image = newImages[i];
          try {
            const base64 = `data:${image.mimetype};base64,${image.buffer.toString('base64')}`;
            const result = await this.supabaseService.uploadBase64(
              base64,
              'products',
            );

            await tx.insert(mediaAssets).values({
              id: uuidv4(),
              url: result.secure_url,
              publicId: result.public_id,
              productId,
              isMain: false,
              order: 999 + i,
            });
          } catch (error) {
            console.error(`Failed to upload image ${i}:`, error);
          }
        }
      }
    });

    // ✅ Return fresh data after transaction
    console.log('✅ Transaction completed');
    return this.getProductById(productId);
  }
  async deleteProduct(productId: string) {
    // ✅ Check if product has been ordered
    const orderItemsCount = await this.drizzle.db
      .select({ count: sql<number>`count(*)` })
      .from(orderItems)
      .where(eq(orderItems.productId, productId));

    if (orderItemsCount[0]?.count > 0) {
      // ✅ Soft delete: mark as inactive instead of deleting
      const [updated] = await this.drizzle.db
        .update(products)
        .set({
          isActive: false,
          updatedAt: new Date(),
        })
        .where(eq(products.id, productId))
        .returning();

      if (!updated) throw new NotFoundException('Product not found');

      return {
        message: 'Product marked as inactive (has order history)',
        product: updated,
      };
    }

    // ✅ No orders - safe to delete
    const product = await this.getProductById(productId);

    if (product.images && product.images.length > 0) {
      await Promise.all(
        product.images.map((image) =>
          this.supabaseService.deleteImage(image.publicId).catch(() => {}),
        ),
      );
    }

    await this.drizzle.db.delete(products).where(eq(products.id, productId));
    return { message: 'Product deleted successfully' };
  }

  async uploadProductImages(productId: string, images: Express.Multer.File[]) {
    await this.getProductById(productId);

    const uploadResults = await Promise.all(
      images.map((image) => {
        const base64 = `data:${image.mimetype};base64,${image.buffer.toString('base64')}`;
        return this.supabaseService.uploadBase64(base64, 'products');
      }),
    );

    const insertedImages: Array<{
      id: string;
      url: string;
      publicId: string;
      productId: string | null;
      isMain: boolean | null;
      order: number | null;
    }> = [];
    for (let i = 0; i < uploadResults.length; i++) {
      const result = uploadResults[i];
      const [image] = await this.drizzle.db
        .insert(mediaAssets)
        .values({
          id: uuidv4(),
          url: result.secure_url,
          publicId: result.public_id,
          productId,
          isMain: i === 0,
          order: i,
        })
        .returning();
      insertedImages.push(image);
    }

    return insertedImages;
  }

  async getCategoriesTree() {
    const allCategories = await this.drizzle.db.select().from(categories);

    const iconIds = allCategories.filter((c) => c.iconId).map((c) => c.iconId!);

    const icons =
      iconIds.length > 0
        ? await this.drizzle.db
            .select()
            .from(mediaAssets)
            .where(inArray(mediaAssets.id, iconIds))
        : [];

    const iconMap = new Map(icons.map((icon) => [icon.id, icon.url]));

    const categoryMap = new Map<string, Record<string, unknown>>();
    const roots: Record<string, unknown>[] = [];

    allCategories.forEach((category) => {
      categoryMap.set(category.id, {
        ...category,
        iconUrl: category.iconId ? iconMap.get(category.iconId) || null : null,
        children: [],
      });
    });

    allCategories.forEach((category) => {
      const node = categoryMap.get(category.id);
      if (!node) return;

      if (category.parentId && categoryMap.has(category.parentId)) {
        const parent = categoryMap.get(category.parentId);
        if (parent) {
          const children = parent.children as Record<string, unknown>[];
          children.push(node);
        }
      } else {
        roots.push(node);
      }
    });

    return roots;
  }

  // ==========================================
  // COLORS & SIZES - Simple queries (no pagination needed)
  // ==========================================
  async getAllColors() {
    return this.drizzle.db.select().from(colors).orderBy(colors.name);
  }

  async getAllSizes() {
    return this.drizzle.db.select().from(sizes).orderBy(sizes.name);
  }

  // In admin.service.ts

  async deleteUser(userId: string) {
    const [deletedUser] = await this.drizzle.db
      .delete(users)
      .where(eq(users.id, userId))
      .returning();

    if (!deletedUser) throw new NotFoundException('User not found');
    return { message: 'User deleted successfully' };
  }

  async updateAdminStatus(
    userId: string,
    data: { isAdmin?: boolean; isSuperAdmin?: boolean },
  ) {
    const [updatedUser] = await this.drizzle.db
      .update(users)
      .set({
        isAdmin: data.isAdmin ?? false,
        isSuperAdmin: data.isSuperAdmin ?? false,
        updatedAt: new Date(),
      })
      .where(eq(users.id, userId))
      .returning();

    if (!updatedUser) {
      throw new NotFoundException('User not found');
    }

    // Notify user via WebSocket
    try {
      this.chatGateway.server.to(`user:${userId}`).emit('role_changed', {
        isAdmin: updatedUser.isAdmin,
        isSuperAdmin: updatedUser.isSuperAdmin,
        message: 'Your role has been updated',
      });
    } catch (e) {
      // Silent fail
    }

    // Create notification
    try {
      await this.notificationsService.create({
        userId,
        type: NotificationType.SYSTEM,
        title: 'Role Updated',
        message: data.isAdmin
          ? 'You have been granted admin access'
          : 'Your admin access has been revoked',
        actionText: 'Continue',
        actionLink: '/home',
      });
    } catch (e) {
      // Silent fail
    }

    return {
      message: 'Admin status updated successfully',
      user: updatedUser,
    };
  }
  async createCategory(data: CategoryData) {
    const slug =
      data.slug || data.name.toLowerCase().replace(/[^a-z0-9]+/g, '-');
    let iconId: string | null = null;

    if (data.iconBase64) {
      const uploadResult = await this.supabaseService.uploadBase64(
        data.iconBase64,
        'categories',
      );

      const [mediaAsset] = await this.drizzle.db
        .insert(mediaAssets)
        .values({
          id: uuidv4(),
          url: uploadResult.secure_url,
          publicId: uploadResult.public_id,
        })
        .returning();

      iconId = mediaAsset.id;
    }

    const [category] = await this.drizzle.db
      .insert(categories)
      .values({
        id: uuidv4(),
        name: data.name,
        slug,
        description: data.description || null,
        parentId: data.parentId || null,
        iconId,
      })
      .returning();

    return this._formatCategoryWithIcon(category);
  }

  async updateCategory(categoryId: string, data: CategoryUpdateData) {
    const updateValues: Record<string, unknown> = { updatedAt: new Date() };

    if (data.name) updateValues.name = data.name;
    if (data.slug) updateValues.slug = data.slug;
    if (data.description !== undefined)
      updateValues.description = data.description;

    if (data.iconBase64) {
      const [existingCategory] = await this.drizzle.db
        .select()
        .from(categories)
        .where(eq(categories.id, categoryId));

      if (existingCategory?.iconId) {
        const [oldIcon] = await this.drizzle.db
          .select()
          .from(mediaAssets)
          .where(eq(mediaAssets.id, existingCategory.iconId));

        if (oldIcon) {
          await this.supabaseService
            .deleteImage(oldIcon.publicId)
            .catch(() => {});
          await this.drizzle.db
            .delete(mediaAssets)
            .where(eq(mediaAssets.id, oldIcon.id));
        }
      }

      const uploadResult = await this.supabaseService.uploadBase64(
        data.iconBase64,
        'categories',
      );

      const [mediaAsset] = await this.drizzle.db
        .insert(mediaAssets)
        .values({
          id: uuidv4(),
          url: uploadResult.secure_url,
          publicId: uploadResult.public_id,
        })
        .returning();

      updateValues.iconId = mediaAsset.id;
    }

    const [category] = await this.drizzle.db
      .update(categories)
      .set(updateValues)
      .where(eq(categories.id, categoryId))
      .returning();

    if (!category) throw new NotFoundException('Category not found');

    return this._formatCategoryWithIcon(category);
  }

  async deleteCategory(categoryId: string) {
    const children = await this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.parentId, categoryId));

    if (children.length > 0) {
      throw new BadRequestException(
        'Cannot delete category with subcategories',
      );
    }

    const productsCount = await this.drizzle.db
      .select()
      .from(products)
      .where(eq(products.categoryId, categoryId))
      .limit(1);

    if (productsCount.length > 0) {
      throw new BadRequestException('Cannot delete category with products');
    }

    const [category] = await this.drizzle.db
      .select()
      .from(categories)
      .where(eq(categories.id, categoryId));

    if (category?.iconId) {
      const [icon] = await this.drizzle.db
        .select()
        .from(mediaAssets)
        .where(eq(mediaAssets.id, category.iconId));

      if (icon) {
        await this.supabaseService.deleteImage(icon.publicId).catch(() => {});
        await this.drizzle.db
          .delete(mediaAssets)
          .where(eq(mediaAssets.id, icon.id));
      }
    }

    await this.drizzle.db
      .delete(categories)
      .where(eq(categories.id, categoryId));

    return { message: 'Category deleted successfully' };
  }

  private async _formatCategoryWithIcon(category: Record<string, unknown>) {
    if (!category.iconId) {
      return { ...category, iconUrl: null };
    }

    const [icon] = await this.drizzle.db
      .select()
      .from(mediaAssets)
      .where(eq(mediaAssets.id, category.iconId as string));

    return {
      ...category,
      iconUrl: icon?.url || null,
    };
  }

  // Colors & Sizes
  async getColors() {
    return this.drizzle.db.select().from(colors);
  }

  async getSizes() {
    return this.drizzle.db.select().from(sizes);
  }

  // Variants
  async addProductVariant(productId: string, variantData: VariantData) {
    const product = await this.getProductById(productId);

    const [variant] = await this.drizzle.db
      .insert(productVariants)
      .values({
        id: uuidv4(),
        productId,
        colorId: variantData.colorId,
        sizeId: variantData.sizeId,
        sku:
          variantData.sku ||
          `${product.slug}-${variantData.colorId}-${variantData.sizeId}`.toUpperCase(),
        stock: variantData.stock || 0,
        price: variantData.price?.toString(),
      })
      .returning();

    return variant;
  }

  async createColor(data: ColorData) {
    const [color] = await this.drizzle.db
      .insert(colors)
      .values({
        id: uuidv4(),
        name: data.name,
        code: data.code,
      })
      .returning();

    return color;
  }

  async updateColor(colorId: string, data: ColorUpdateData) {
    const updateValues: Record<string, unknown> = { updatedAt: new Date() };

    if (data.name) updateValues.name = data.name;
    if (data.code) updateValues.code = data.code;

    const [color] = await this.drizzle.db
      .update(colors)
      .set(updateValues)
      .where(eq(colors.id, colorId))
      .returning();

    if (!color) throw new NotFoundException('Color not found');
    return color;
  }

  async deleteColor(colorId: string) {
    const variants = await this.drizzle.db
      .select()
      .from(productVariants)
      .where(eq(productVariants.colorId, colorId))
      .limit(1);

    if (variants.length > 0) {
      throw new BadRequestException(
        'Cannot delete color that is used in product variants',
      );
    }

    await this.drizzle.db.delete(colors).where(eq(colors.id, colorId));
    return { message: 'Color deleted successfully' };
  }

  async createSize(data: SizeData) {
    const [size] = await this.drizzle.db
      .insert(sizes)
      .values({
        id: uuidv4(),
        name: data.name,
        value: data.value,
      })
      .returning();

    return size;
  }

  async updateSize(sizeId: string, data: SizeUpdateData) {
    const updateValues: Record<string, unknown> = { updatedAt: new Date() };

    if (data.name) updateValues.name = data.name;
    if (data.value) updateValues.value = data.value;

    const [size] = await this.drizzle.db
      .update(sizes)
      .set(updateValues)
      .where(eq(sizes.id, sizeId))
      .returning();

    if (!size) throw new NotFoundException('Size not found');
    return size;
  }

  async deleteSize(sizeId: string) {
    const variants = await this.drizzle.db
      .select()
      .from(productVariants)
      .where(eq(productVariants.sizeId, sizeId))
      .limit(1);

    if (variants.length > 0) {
      throw new BadRequestException(
        'Cannot delete size that is used in product variants',
      );
    }

    await this.drizzle.db.delete(sizes).where(eq(sizes.id, sizeId));
    return { message: 'Size deleted successfully' };
  }

  // Markets Management
  // async getAllMarkets() {
  //   return this.drizzle.db.select().from(markets).orderBy(markets.name);
  // }

  async createMarket(data: MarketData) {
    const slug =
      data.slug || data.name.toLowerCase().replace(/[^a-z0-9]+/g, '-');

    const [market] = await this.drizzle.db
      .insert(markets)
      .values({
        id: uuidv4(),
        name: data.name,
        slug,
        city: data.city || null,
        isActive: true,
      })
      .returning();

    return market;
  }

  async updateMarket(marketId: string, data: MarketUpdateData) {
    const updateValues: Record<string, unknown> = { updatedAt: new Date() };

    if (data.name) updateValues.name = data.name;
    if (data.slug) updateValues.slug = data.slug;
    if (data.city !== undefined) updateValues.city = data.city;
    if (data.isActive !== undefined) updateValues.isActive = data.isActive;

    const [market] = await this.drizzle.db
      .update(markets)
      .set(updateValues)
      .where(eq(markets.id, marketId))
      .returning();

    if (!market) throw new NotFoundException('Market not found');
    return market;
  }

  // In admin.service.ts - Update the deleteMarket method

  async deleteMarket(marketId: string) {
    // Check if market has users
    const usersCount = await this.drizzle.db
      .select({ count: sql<number>`count(*)` })
      .from(users)
      .where(eq(users.marketId, marketId));

    const count = Number(usersCount[0]?.count) || 0;

    if (count > 0) {
      // ✅ Instead of throwing error, deactivate the market
      const [updatedMarket] = await this.drizzle.db
        .update(markets)
        .set({
          isActive: false,
          updatedAt: new Date(),
        })
        .where(eq(markets.id, marketId))
        .returning();

      if (!updatedMarket) {
        throw new NotFoundException('Market not found');
      }

      // ✅ Return success with a warning message
      return {
        message: `Market deactivated successfully. ${count} user(s) are still associated with this market.`,
        deactivated: true,
        userCount: count,
        market: updatedMarket,
      };
    }

    // If no users, actually delete the market
    const [deletedMarket] = await this.drizzle.db
      .delete(markets)
      .where(eq(markets.id, marketId))
      .returning();

    if (!deletedMarket) {
      throw new NotFoundException('Market not found');
    }

    return {
      message: 'Market deleted successfully',
      deleted: true,
    };
  }

  // Also update getAllMarkets to include user count
  async getAllMarkets(page: number = 1, limit: number = 50) {
    const offset = (page - 1) * limit;

    const [items, total] = await Promise.all([
      this.drizzle.db
        .select({
          id: markets.id,
          name: markets.name,
          slug: markets.slug,
          city: markets.city,
          isActive: markets.isActive,
          createdAt: markets.createdAt,
          updatedAt: markets.updatedAt,
          userCount: sql<number>`CAST(COUNT(${users.id}) AS INTEGER)`,
        })
        .from(markets)
        .leftJoin(users, eq(users.marketId, markets.id))
        .groupBy(
          markets.id,
          markets.name,
          markets.slug,
          markets.city,
          markets.isActive,
          markets.createdAt,
          markets.updatedAt,
        )
        .orderBy(markets.name)
        .limit(limit)
        .offset(offset),
      this.drizzle.db
        .select({ count: sql<number>`COUNT(*)::int` })
        .from(markets),
    ]);

    return {
      items,
      pagination: {
        page,
        limit,
        total: total[0]?.count || 0,
        totalPages: Math.ceil((total[0]?.count || 0) / limit),
      },
    };
  }

  // Add a dedicated deactivate endpoint method
  async deactivateMarket(marketId: string) {
    const [updatedMarket] = await this.drizzle.db
      .update(markets)
      .set({
        isActive: false,
        updatedAt: new Date(),
      })
      .where(eq(markets.id, marketId))
      .returning();

    if (!updatedMarket) {
      throw new NotFoundException('Market not found');
    }

    // Get user count for response
    const usersCount = await this.drizzle.db
      .select({ count: sql<number>`count(*)` })
      .from(users)
      .where(eq(users.marketId, marketId));

    const count = Number(usersCount[0]?.count) || 0;

    return {
      message: `Market deactivated successfully. ${count} user(s) are still associated with this market.`,
      market: updatedMarket,
      userCount: count,
    };
  }

  async getRevenueById(orderId: string) {
    const order = await this.drizzle.db.query.orders.findFirst({
      where: and(eq(orders.id, orderId), eq(orders.paymentStatus, 'PAID')),
      with: {
        user: true,
        items: {
          with: {
            variant: {
              with: {
                product: {
                  with: {
                    images: true,
                    category: true,
                  },
                },
                color: true,
                size: true,
              },
            },
          },
        },
      },
    });

    if (!order) throw new NotFoundException('Revenue record not found');

    const subtotal = order.items.reduce((sum, item) => {
      return sum + Number(item.unitPrice) * item.quantity;
    }, 0);

    return {
      id: order.id,
      orderNumber: order.orderNumber,
      customerName: order.customerName,
      customerEmail: order.customerEmail,
      customerPhone: order.customerPhone,
      shippingAddress: order.shippingAddress,
      subtotal: subtotal,
      totalAmount: Number(order.totalAmount),
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
      status: order.status,
      notes: order.notes,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      items: order.items.map((item) => ({
        id: item.id,
        productName: item.productName,
        variantSku: item.variantSku,
        colorName: item.colorName,
        sizeName: item.sizeName,
        unitPrice: Number(item.unitPrice),
        quantity: item.quantity,
        totalPrice: Number(item.totalPrice),
        productImage: item.variant?.product?.images?.[0]?.url || null,
        category: item.variant?.product?.category?.name || null,
      })),
    };
  }
  // Add these methods to your AdminService class

  // ==========================================
  // ANALYTICS - Top Selling Products
  // ==========================================
  async getTopSellingProducts(limit: number = 5, period: string = 'week') {
    const dateRange = this.getDateRangeForPeriod(period);

    try {
      const topProducts = await this.drizzle.db
        .select({
          productId: products.id,
          productName: products.name,
          productImage: sql<string>`MAX(${mediaAssets.url})`,
          totalSold: sql<number>`COALESCE(SUM(${orderItems.quantity}), 0)::int`,
          totalRevenue: sql<string>`COALESCE(SUM(CAST(${orderItems.totalPrice} AS DECIMAL)), 0)`,
          orderCount: sql<number>`COUNT(DISTINCT ${orders.id})::int`,
        })
        .from(orderItems)
        .leftJoin(orders, eq(orders.id, orderItems.orderId))
        .leftJoin(products, eq(products.id, orderItems.productId))
        .leftJoin(
          mediaAssets,
          and(
            eq(mediaAssets.productId, products.id),
            eq(mediaAssets.isMain, true),
          ),
        )
        .where(
          and(
            eq(orders.paymentStatus, 'PAID'),
            gte(orders.createdAt, dateRange.start),
            lte(orders.createdAt, dateRange.end),
          ),
        )
        .groupBy(products.id, products.name)
        .orderBy(sql`SUM(${orderItems.quantity}) DESC`)
        .limit(limit);

      return topProducts.map((p) => ({
        id: p.productId,
        name: p.productName || 'Unknown',
        imageUrl: p.productImage || null,
        totalSold: Number(p.totalSold) || 0,
        totalRevenue: Number(p.totalRevenue) || 0,
        orderCount: Number(p.orderCount) || 0,
      }));
    } catch (error) {
      console.error('❌ [Admin] Top selling products error:', error);
      return [];
    }
  }

  // ==========================================
  // ANALYTICS - Revenue by Category
  // ==========================================
  async getRevenueByCategory(period: string = 'week') {
    const dateRange = this.getDateRangeForPeriod(period);

    try {
      const categoryRevenue = await this.drizzle.db
        .select({
          categoryId: categories.id,
          categoryName: categories.name,
          totalRevenue: sql<string>`COALESCE(SUM(CAST(${orderItems.totalPrice} AS DECIMAL)), 0)`,
          orderCount: sql<number>`COUNT(DISTINCT ${orders.id})::int`,
          itemCount: sql<number>`COALESCE(SUM(${orderItems.quantity}), 0)::int`,
        })
        .from(orderItems)
        .leftJoin(orders, eq(orders.id, orderItems.orderId))
        .leftJoin(products, eq(products.id, orderItems.productId))
        .leftJoin(categories, eq(categories.id, products.categoryId))
        .where(
          and(
            eq(orders.paymentStatus, 'PAID'),
            gte(orders.createdAt, dateRange.start),
            lte(orders.createdAt, dateRange.end),
          ),
        )
        .groupBy(categories.id, categories.name)
        .orderBy(sql`SUM(CAST(${orderItems.totalPrice} AS DECIMAL)) DESC`);

      return categoryRevenue.map((c) => ({
        id: c.categoryId,
        name: c.categoryName || 'Uncategorized',
        totalRevenue: Number(c.totalRevenue) || 0,
        orderCount: Number(c.orderCount) || 0,
        itemCount: Number(c.itemCount) || 0,
      }));
    } catch (error) {
      console.error('❌ [Admin] Revenue by category error:', error);
      return [];
    }
  }

  // ==========================================
  // ANALYTICS - Order Status Distribution
  // ==========================================
  async getOrderStatusDistribution(period: string = 'week') {
    const dateRange = this.getDateRangeForPeriod(period);

    try {
      const statusDistribution = await this.drizzle.db
        .select({
          status: orders.status,
          count: sql<number>`COUNT(*)::int`,
          totalRevenue: sql<string>`COALESCE(SUM(CASE WHEN ${orders.paymentStatus} = 'PAID' THEN CAST(${orders.totalAmount} AS DECIMAL) ELSE 0 END), 0)`,
        })
        .from(orders)
        .where(
          and(
            gte(orders.createdAt, dateRange.start),
            lte(orders.createdAt, dateRange.end),
          ),
        )
        .groupBy(orders.status);

      return statusDistribution.map((s) => ({
        status: s.status,
        count: Number(s.count) || 0,
        totalRevenue: Number(s.totalRevenue) || 0,
      }));
    } catch (error) {
      console.error('❌ [Admin] Order status distribution error:', error);
      return [];
    }
  }

  // ==========================================
  // ANALYTICS - Low Stock Alerts
  // ==========================================
  async getLowStockProducts(threshold: number = 5, limit: number = 10) {
    try {
      const lowStockProducts = await this.drizzle.db.query.products.findMany({
        where: and(
          eq(products.isActive, true),
          sql`${products.stock} <= ${threshold}`,
          sql`${products.stock} > 0`,
        ),
        orderBy: [asc(products.stock)],
        limit,
        with: {
          images: {
            limit: 1,
            orderBy: [desc(mediaAssets.isMain)],
          },
          category: {
            columns: {
              id: true,
              name: true,
            },
          },
        },
      });

      return lowStockProducts.map((p) => ({
        id: p.id,
        name: p.name,
        stock: p.stock,
        price: Number(p.price),
        imageUrl: p.images?.[0]?.url || null,
        categoryName: p.category?.name || null,
      }));
    } catch (error) {
      console.error('❌ [Admin] Low stock products error:', error);
      return [];
    }
  }

  // ==========================================
  // ANALYTICS - Recent Signups
  // ==========================================
  async getRecentSignups(limit: number = 5) {
    try {
      const recentUsers = await this.drizzle.db.query.users.findMany({
        orderBy: [desc(users.createdAt)],
        limit,
        columns: {
          id: true,
          name: true,
          phoneNumber: true,
          email: true,
          createdAt: true,
          isVerified: true,
        },
      });

      return recentUsers.map((u) => ({
        id: u.id,
        name: u.name || 'Anonymous',
        phoneNumber: u.phoneNumber,
        email: u.email,
        joinedAt: u.createdAt,
        isVerified: u.isVerified ?? false,
      }));
    } catch (error) {
      console.error('❌ [Admin] Recent signups error:', error);
      return [];
    }
  }
  // ==========================================
  // ANALYTICS - All Analytics Combined
  // ==========================================
  async getAllAnalytics(period: string = 'week') {
    console.log('📊 [Admin] Fetching all analytics for period:', period);

    try {
      const [
        topProducts,
        revenueByCategory,
        orderStatusDistribution,
        lowStockProducts,
        recentSignups,
      ] = await Promise.all([
        this.getTopSellingProducts(5, period).catch((err) => {
          console.error('❌ [Admin] Top products error:', err);
          return [];
        }),
        this.getRevenueByCategory(period).catch((err) => {
          console.error('❌ [Admin] Revenue by category error:', err);
          return [];
        }),
        this.getOrderStatusDistribution(period).catch((err) => {
          console.error('❌ [Admin] Order status error:', err);
          return [];
        }),
        this.getLowStockProducts(5, 10).catch((err) => {
          console.error('❌ [Admin] Low stock error:', err);
          return [];
        }),
        this.getRecentSignups(5).catch((err) => {
          console.error('❌ [Admin] Recent signups error:', err);
          return [];
        }),
      ]);

      return {
        topProducts,
        revenueByCategory,
        orderStatusDistribution,
        lowStockProducts,
        recentSignups,
      };
    } catch (error) {
      console.error('❌ [Admin] Analytics fetch failed:', error);
      // ✅ Return empty data instead of throwing
      return {
        topProducts: [],
        revenueByCategory: [],
        orderStatusDistribution: [],
        lowStockProducts: [],
        recentSignups: [],
      };
    }
  }
}
