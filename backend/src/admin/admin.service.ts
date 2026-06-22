import { Injectable, NotFoundException } from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { orders, products, users, notifications } from '../drizzle/schema';
import { sql, eq, desc, or, like } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class AdminService {
  constructor(private drizzle: DrizzleService) {}

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

  // ✅ CLEANED UP: Removed unused query variable
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

  // ✅ NEW: Dedicated admin status update method
  async updateOrderStatus(orderId: string, status: string) {
    const [order] = await this.drizzle.db
      .update(orders)
      .set({ status, updatedAt: new Date() })
      .where(eq(orders.id, orderId))
      .returning();

    if (!order) throw new NotFoundException('Order not found');

    // Create notification for the user
    await this.drizzle.db.insert(notifications).values({
      id: uuidv4(),
      userId: order.userId!,
      type: 'order',
      title: 'Order Status Updated',
      message: `Your order #${order.orderNumber} is now ${status.toLowerCase()}`,
      actionText: 'View Order',
      actionLink: `/orders/${order.id}`,
    });

    return {
      message: 'Order status updated successfully',
      order: {
        id: order.id,
        orderNumber: order.orderNumber,
        status: order.status,
      },
    };
  }

  async getAllProducts() {
    return this.drizzle.db.query.products.findMany({
      orderBy: [desc(products.createdAt)],
      with: { images: true, category: true },
    });
  }

  async getAllUsers() {
    return this.drizzle.db.select().from(users).orderBy(desc(users.createdAt));
  }
}
