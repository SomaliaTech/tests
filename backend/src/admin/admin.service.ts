import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { CloudflareService } from '../cloudfare/cloudflare.service';
import {
  orders,
  products,
  users,
  notifications,
  orderItems,
  productVariants,
  categories,
  mediaAssets,
} from '../drizzle/schema';
import { sql, eq, desc, or, like, and, gte, lte, lt } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';
import { colors, sizes } from '../drizzle/schema';
import { SupabaseService } from 'src/supabase/supabase.service';
import { CreateProductAdminDto } from './dto/create-proudct-admin-dto';
@Injectable()
export class AdminService {
  constructor(
    private drizzle: DrizzleService,
    private cloudflareService: CloudflareService,
    private supabaseService: SupabaseService, // ✅ Changed
  ) {}

  async getStats() {
    const [productStats] = await this.drizzle.db
      .select({ count: sql<number>`count(*)` })
      .from(products);

    const [orderStats] = await this.drizzle.db
      .select({ count: sql<number>`count(*)` })
      .from(orders);

    const [revenueStats] = await this.drizzle.db
      .select({
        total: sql<string>`COALESCE(SUM(CAST(total_amount AS DECIMAL)), 0)`,
      })
      .from(orders)
      .where(eq(orders.paymentStatus, 'PAID'));

    const [userStats] = await this.drizzle.db
      .select({ count: sql<number>`count(*)` })
      .from(users);

    return {
      totalProducts: Number(productStats.count) || 0,
      totalOrders: Number(orderStats.count) || 0,
      totalRevenue: Number(revenueStats.total) || 0,
      totalUsers: Number(userStats.count) || 0,
    };
  }

  async getAllOrders(search?: string) {
    if (search && search.trim()) {
      const searchPattern = `%${search.trim()}%`;
      return this.drizzle.db.query.orders.findMany({
        where: or(
          like(orders.orderNumber, searchPattern),
          like(orders.customerName, searchPattern),
          like(orders.customerEmail, searchPattern),
        ),
        orderBy: [desc(orders.createdAt)],
        with: {
          user: true,
          items: {
            with: {
              variant: {
                with: {
                  product: true,
                },
              },
            },
          },
        },
      });
    }

    return this.drizzle.db.query.orders.findMany({
      orderBy: [desc(orders.createdAt)],
      with: {
        user: true,
        items: {
          with: {
            variant: {
              with: {
                product: true,
              },
            },
          },
        },
      },
    });
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

  async updateOrderStatus(orderId: string, status: string) {
    const [order] = await this.drizzle.db
      .update(orders)
      .set({ status, updatedAt: new Date() })
      .where(eq(orders.id, orderId))
      .returning();

    if (!order) throw new NotFoundException('Order not found');

    if (order.userId) {
      await this.drizzle.db.insert(notifications).values({
        id: uuidv4(),
        userId: order.userId,
        type: 'order',
        title: 'Order Status Updated',
        message: `Your order #${order.orderNumber} is now ${status.toLowerCase()}`,
        actionText: 'View Order',
        actionLink: `/orders/${order.id}`,
      });
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

  async deleteUser(userId: string) {
    const [deletedUser] = await this.drizzle.db
      .delete(users)
      .where(eq(users.id, userId))
      .returning();

    if (!deletedUser) throw new NotFoundException('User not found');

    return { message: 'User deleted successfully' };
  }

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

    return { message: 'User created successfully', user: newUser };
  }

  async getAllProducts() {
    return this.drizzle.db.query.products.findMany({
      orderBy: [desc(products.createdAt)],
      with: { images: true, category: true },
    });
  }

  async getAllUsers(search?: string) {
    if (search && search.trim()) {
      const searchPattern = `%${search.trim()}%`;
      return this.drizzle.db.query.users.findMany({
        where: or(
          like(users.name, searchPattern),
          like(users.email, searchPattern),
          like(users.phoneNumber, searchPattern),
        ),
        orderBy: [desc(users.createdAt)],
        with: { addresses: true },
      });
    }

    return this.drizzle.db.query.users.findMany({
      orderBy: [desc(users.createdAt)],
      with: { addresses: true },
    });
  }

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
    const periodMap = {
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
    const result: any[] = [];
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

  async getDeviceTraffic() {
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
    } catch (error) {
      return [
        { productId: 'mock-1', productName: 'iPhone 15 Pro', views: 45 },
        { productId: 'mock-2', productName: 'MacBook Pro', views: 32 },
        { productId: 'mock-3', productName: 'AirPods Pro', views: 28 },
      ];
    }
  }

  async getRecentOrders(limit: number = 5) {
    const recentOrders = await this.drizzle.db.query.orders.findMany({
      orderBy: [desc(orders.createdAt)],
      limit,
      with: { items: true, user: true },
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
    limit: number = 50,
    offset: number = 0,
  ) {
    const conditions: any[] = [eq(orders.paymentStatus, 'PAID')];

    if (search && search.trim()) {
      const searchPattern = `%${search.trim()}%`;
      conditions.push(
        or(
          like(orders.orderNumber, searchPattern),
          like(orders.customerName, searchPattern),
          like(orders.customerEmail, searchPattern),
        )!,
      );
    }

    if (paymentMethod) {
      conditions.push(eq(orders.paymentMethod, paymentMethod));
    }

    if (status) {
      conditions.push(eq(orders.status, status));
    }

    const revenueOrders = await this.drizzle.db.query.orders.findMany({
      where: and(...conditions),
      orderBy: [desc(orders.createdAt)],
      limit,
      offset,
      with: {
        user: true,
        items: {
          with: {
            variant: {
              with: {
                product: true,
              },
            },
          },
        },
      },
    });

    const [totalCount] = await this.drizzle.db
      .select({ count: sql<number>`COUNT(*)::int` })
      .from(orders)
      .where(and(...conditions));

    return {
      data: revenueOrders.map((order) => ({
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
      total: Number(totalCount.count) || 0,
      limit,
      offset,
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

  // ==========================================
  // ADMIN PRODUCTS MANAGEMENT
  // ==========================================
  async getAllProductsAdmin() {
    return this.drizzle.db.query.products.findMany({
      orderBy: [desc(products.createdAt)],
      with: {
        category: true,
        images: true,
        variants: {
          with: {
            color: true,
            size: true,
          },
        },
      },
    });
  }

  async getProductById(productId: string) {
    const product = await this.drizzle.db.query.products.findFirst({
      where: eq(products.id, productId),
      with: {
        category: true,
        images: true,
        variants: {
          with: {
            color: true,
            size: true,
          },
        },
      },
    });

    if (!product) throw new NotFoundException('Product not found');
    return product;
  }
  async createProduct(createProductDto: CreateProductAdminDto) {
    const productId = uuidv4();

    const slug =
      createProductDto.slug ||
      createProductDto.name
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-|-$/g, '');

    // ✅ DYNAMIC INSERT: Only add fields that have actual values
    // This prevents sending null/undefined to columns that might not accept them
    const insertData: any = {
      id: productId,
      name: createProductDto.name,
      slug: slug,
      price: createProductDto.price.toString(), // Numeric columns in Drizzle usually expect strings
      stock: createProductDto.stock ?? 0,
      isActive: createProductDto.isActive ?? true,
      isFeatured: createProductDto.isFeatured ?? false,
      categoryId: createProductDto.categoryId,
    };

    // Add optional string fields
    if (createProductDto.description)
      insertData.description = createProductDto.description;
    if (createProductDto.sku) insertData.sku = createProductDto.sku;
    if (createProductDto.barcode) insertData.barcode = createProductDto.barcode;
    if (createProductDto.brand) insertData.brand = createProductDto.brand;
    if (createProductDto.tags) insertData.tags = createProductDto.tags;
    if (createProductDto.seoTitle)
      insertData.seoTitle = createProductDto.seoTitle;
    if (createProductDto.seoDescription)
      insertData.seoDescription = createProductDto.seoDescription;

    // Add optional numeric fields (convert to string for Postgres numeric types)
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
      const [product] = await this.drizzle.db
        .insert(products)
        .values(insertData)
        .returning();

      // Handle Variants
      if (createProductDto.variants && createProductDto.variants.length > 0) {
        for (const variant of createProductDto.variants) {
          await this.drizzle.db.insert(productVariants).values({
            id: uuidv4(),
            productId,
            colorId: variant.colorId,
            sizeId: variant.sizeId,
            sku:
              variant.sku ||
              `${slug}-${variant.colorId}-${variant.sizeId}`.toUpperCase(),
            stock: variant.stock ?? 0,
            price: variant.price?.toString(),
          });
        }
      }

      return this.getProductById(productId);
    } catch (error: any) {
      // ✅ THIS WILL PRINT THE EXACT POSTGRES ERROR
      console.error('❌ Database Insert Error:', error.message);
      if (error.detail) console.error('🔍 Error Detail:', error.detail);
      throw new BadRequestException(
        `Failed to create product: ${error.detail || error.message}`,
      );
    }
  }
  async updateProduct(productId: string, updateData: any) {
    const updateValues: any = { updatedAt: new Date() };

    if (updateData.name !== undefined) updateValues.name = updateData.name;
    if (updateData.description !== undefined)
      updateValues.description = updateData.description;
    if (updateData.price !== undefined)
      updateValues.price = updateData.price.toString();
    if (updateData.stock !== undefined) updateValues.stock = updateData.stock;
    if (updateData.categoryId !== undefined)
      updateValues.categoryId = updateData.categoryId;
    if (updateData.brand !== undefined) updateValues.brand = updateData.brand;
    if (updateData.tags !== undefined) updateValues.tags = updateData.tags;
    if (updateData.isActive !== undefined)
      updateValues.isActive = updateData.isActive;

    const [updated] = await this.drizzle.db
      .update(products)
      .set(updateValues)
      .where(eq(products.id, productId))
      .returning();

    if (!updated) throw new NotFoundException('Product not found');

    return this.getProductById(updated.id);
  }

  // ✅ Updated deleteProduct to use Supabase
  async deleteProduct(productId: string) {
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

  // ✅ Updated uploadProductImages to use Supabase

  async getCategoriesTree() {
    const allCategories = await this.drizzle.db.select().from(categories);

    const categoryMap = new Map();
    const roots: any[] = [];

    allCategories.forEach((category) => {
      categoryMap.set(category.id, { ...category, children: [] });
    });

    allCategories.forEach((category) => {
      const node = categoryMap.get(category.id);
      if (category.parentId && categoryMap.has(category.parentId)) {
        const parent = categoryMap.get(category.parentId);
        if (parent) {
          parent.children.push(node);
        }
      } else {
        roots.push(node);
      }
    });

    return roots;
  }

  async uploadProductImages(productId: string, images: Express.Multer.File[]) {
    const product = await this.getProductById(productId);

    const uploadResults = await Promise.all(
      images.map((image) => {
        const base64 = `data:${image.mimetype};base64,${image.buffer.toString('base64')}`;
        return this.supabaseService.uploadBase64(base64, 'products');
      }),
    );

    const insertedImages: any[] = [];
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
  async getColors() {
    return this.drizzle.db.select().from(colors);
  }

  async getSizes() {
    return this.drizzle.db.select().from(sizes);
  }

  async addProductVariant(productId: string, variantData: any) {
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
}
