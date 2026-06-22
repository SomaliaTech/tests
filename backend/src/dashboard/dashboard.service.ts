import { Injectable } from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { orders, products, users, orderItems } from '../drizzle/schema';
import { sql, eq, desc, sum, count, gt, lt, and, gte, lte } from 'drizzle-orm';

@Injectable()
export class DashboardService {
  constructor(private drizzle: DrizzleService) {}

  private getDateRange(period: string) {
    const now = new Date();
    const startDate = new Date();

    switch (period) {
      case 'day':
        startDate.setDate(now.getDate() - 1);
        break;
      case 'week':
        startDate.setDate(now.getDate() - 7);
        break;
      case 'month':
        startDate.setMonth(now.getMonth() - 1);
        break;
      case 'year':
        startDate.setFullYear(now.getFullYear() - 1);
        break;
      default:
        startDate.setDate(now.getDate() - 7);
    }

    return { startDate, endDate: now };
  }

  async getDashboardStats(period: string = 'week') {
    const { startDate } = this.getDateRange(period);

    const [totalUsers] = await this.drizzle.db
      .select({ count: count() })
      .from(users);

    const [totalProducts] = await this.drizzle.db
      .select({ count: count() })
      .from(products);

    const [totalOrders] = await this.drizzle.db
      .select({ count: count() })
      .from(orders);

    const [revenueData] = await this.drizzle.db
      .select({ total: sum(orders.totalAmount) })
      .from(orders)
      .where(eq(orders.paymentStatus, 'PAID'));

    // Get new users in period
    const [newUsers] = await this.drizzle.db
      .select({ count: count() })
      .from(users)
      .where(gte(users.createdAt, startDate));

    // Get orders in period
    const [ordersInPeriod] = await this.drizzle.db
      .select({ count: count() })
      .from(orders)
      .where(gte(orders.createdAt, startDate));

    // Calculate growth percentages (simplified)
    const previousPeriodStart = new Date(startDate);
    const daysDiff = Math.floor(
      (new Date().getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24),
    );
    previousPeriodStart.setDate(previousPeriodStart.getDate() - daysDiff);

    const [previousUsers] = await this.drizzle.db
      .select({ count: count() })
      .from(users)
      .where(
        and(
          gte(users.createdAt, previousPeriodStart),
          lt(users.createdAt, startDate),
        ),
      );

    const userGrowth =
      previousUsers.count > 0
        ? (
            ((newUsers.count - previousUsers.count) / previousUsers.count) *
            100
          ).toFixed(2)
        : '0.00';

    return {
      totalUsers: Number(totalUsers.count) || 0,
      totalProducts: Number(totalProducts.count) || 0,
      totalOrders: Number(totalOrders.count) || 0,
      totalRevenue: Number(revenueData.total) || 0,
      newUsers: Number(newUsers.count) || 0,
      ordersInPeriod: Number(ordersInPeriod.count) || 0,
      userGrowth: parseFloat(userGrowth),
      period: period,
    };
  }

  async getUsersChartData(period: string = 'week') {
    const { startDate, endDate } = this.getDateRange(period);

    const result = await this.drizzle.db
      .select({
        date: sql<string>`DATE(${users.createdAt})`,
        count: count(),
      })
      .from(users)
      .where(
        and(gte(users.createdAt, startDate), lte(users.createdAt, endDate)),
      )
      .groupBy(sql`DATE(${users.createdAt})`)
      .orderBy(sql`DATE(${users.createdAt})`);

    // Fill in missing dates
    const chartData: any = [];
    const currentDate = new Date(startDate);

    while (currentDate <= endDate) {
      const dateStr = currentDate.toISOString().split('T')[0];
      const found = result.find((r) => r.date === dateStr);

      chartData.push({
        date: dateStr,
        users: found ? Number(found.count) : 0,
      });

      currentDate.setDate(currentDate.getDate() + 1);
    }

    return chartData;
  }

  async getDeviceTraffic() {
    // This is mock data - in real app, track user agents
    return [
      { device: 'Mobile', value: 58, color: '#2ED573' },
      { device: 'Desktop', value: 32, color: '#1E90FF' },
      { device: 'Tablet', value: 10, color: '#FFA502' },
    ];
  }

  async getLocationTraffic() {
    const result = await this.drizzle.db
      .select({
        // 👇 FIX: Cast UUID to TEXT so COALESCE works with 'Unknown'
        location: sql<string>`COALESCE(CAST(${users.marketId} AS TEXT), 'Unknown')`,
        count: count(),
      })
      .from(users)
      // 👇 FIX: Match the exact grouping expression
      .groupBy(sql`COALESCE(CAST(${users.marketId} AS TEXT), 'Unknown')`)
      .orderBy(desc(count()));

    const total = result.reduce((sum, r) => sum + Number(r.count), 0);

    return result.slice(0, 5).map((r) => ({
      location: r.location,
      users: Number(r.count),
      percentage:
        total > 0 ? ((Number(r.count) / total) * 100).toFixed(1) : '0.0',
    }));
  }

  async getProductTraffic(period: string = 'week') {
    const { startDate } = this.getDateRange(period);

    const result = await this.drizzle.db
      .select({
        productName: products.name,
        productId: products.id,
        views: count(),
      })
      .from(orderItems)
      .leftJoin(orders, eq(orderItems.orderId, orders.id))
      .leftJoin(products, eq(orderItems.productVariantId, products.id))
      .where(gte(orders.createdAt, startDate))
      .groupBy(products.id, products.name)
      .orderBy(desc(count()))
      .limit(5);

    return result.map((r) => ({
      productId: r.productId,
      productName: r.productName,
      views: Number(r.views),
    }));
  }

  async getRecentOrders(limit: number = 5) {
    const result = await this.drizzle.db.query.orders.findMany({
      limit: limit,
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

    return result.map((order) => ({
      id: order.id,
      orderNumber: order.orderNumber,
      customerName: order.customerName,
      customerEmail: order.customerEmail,
      totalAmount: Number(order.totalAmount),
      status: order.status,
      paymentStatus: order.paymentStatus,
      createdAt: order.createdAt,
      itemsCount: order.items?.length || 0,
    }));
  }

  async getRevenueChart(period: string = 'week') {
    const { startDate, endDate } = this.getDateRange(period);

    const result = await this.drizzle.db
      .select({
        date: sql<string>`DATE(${orders.createdAt})`,
        revenue: sum(orders.totalAmount),
        count: count(),
      })
      .from(orders)
      .where(
        and(
          gte(orders.createdAt, startDate),
          lte(orders.createdAt, endDate),
          eq(orders.paymentStatus, 'PAID'),
        ),
      )
      .groupBy(sql`DATE(${orders.createdAt})`)
      .orderBy(sql`DATE(${orders.createdAt})`);

    // Fill in missing dates
    const chartData: any = [];
    const currentDate = new Date(startDate);

    while (currentDate <= endDate) {
      const dateStr = currentDate.toISOString().split('T')[0];
      const found = result.find((r) => r.date === dateStr);

      chartData.push({
        date: dateStr,
        revenue: found ? Number(found.revenue) : 0,
        orders: found ? Number(found.count) : 0,
      });

      currentDate.setDate(currentDate.getDate() + 1);
    }

    return chartData;
  }
}
