import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import {
  orders,
  orderItems,
  products,
  productVariants,
  users,
  addresses,
  notifications,
  colors,
  sizes,
  cartItems,
} from '../drizzle/schema';
import { eq, and, sql, desc, inArray } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';
import { CreateOrderDto, AddressDto } from './dto/create-order.dto';

@Injectable()
export class OrdersService {
  constructor(private drizzle: DrizzleService) {}

  // ==========================================
  // ADDRESS MANAGEMENT
  // ==========================================

  async addAddress(userId: string, addressData: AddressDto) {
    if (addressData.isDefault) {
      await this.drizzle.db
        .update(addresses)
        .set({ isDefault: false })
        .where(eq(addresses.userId, userId));
    }

    const [address] = await this.drizzle.db
      .insert(addresses)
      .values({
        id: uuidv4(),
        userId,
        label: addressData.label,
        fullAddress: addressData.fullAddress,
        phoneNumber: addressData.phoneNumber,
        isDefault: addressData.isDefault || false,
      })
      .returning();

    return address;
  }

  async getAddresses(userId: string) {
    return this.drizzle.db
      .select()
      .from(addresses)
      .where(eq(addresses.userId, userId))
      .orderBy(desc(addresses.isDefault));
  }

  async getDefaultAddress(userId: string) {
    const [address] = await this.drizzle.db
      .select()
      .from(addresses)
      .where(and(eq(addresses.userId, userId), eq(addresses.isDefault, true)))
      .limit(1);
    return address;
  }

  async setDefaultAddress(userId: string, addressId: string) {
    await this.drizzle.db
      .update(addresses)
      .set({ isDefault: false })
      .where(eq(addresses.userId, userId));

    const [address] = await this.drizzle.db
      .update(addresses)
      .set({ isDefault: true })
      .where(and(eq(addresses.id, addressId), eq(addresses.userId, userId)))
      .returning();

    if (!address) throw new NotFoundException('Address not found');
    return address;
  }

  async deleteAddress(userId: string, addressId: string) {
    const [deleted] = await this.drizzle.db
      .delete(addresses)
      .where(and(eq(addresses.id, addressId), eq(addresses.userId, userId)))
      .returning();

    if (!deleted) throw new NotFoundException('Address not found');
    return { message: 'Address deleted successfully' };
  }

  // ==========================================
  // ORDER MANAGEMENT (OPTIMIZED)
  // ==========================================

  async createOrder(userId: string, orderData: CreateOrderDto) {
    return this.drizzle.db.transaction(async (tx) => {
      const [user] = await tx.select().from(users).where(eq(users.id, userId));
      if (!user) throw new NotFoundException('User not found');

      const variantIds = orderData.items.map((item) => item.productVariantId);

      const variants = await tx
        .select({
          id: productVariants.id,
          price: productVariants.price,
          sku: productVariants.sku,
          stock: productVariants.stock,
          productId: productVariants.productId,
          productName: products.name,
          colorName: colors.name,
          sizeName: sizes.name,
        })
        .from(productVariants)
        .leftJoin(products, eq(products.id, productVariants.productId))
        .leftJoin(colors, eq(colors.id, productVariants.colorId))
        .leftJoin(sizes, eq(sizes.id, productVariants.sizeId))
        .where(inArray(productVariants.id, variantIds));

      const variantMap = new Map(variants.map((v) => [v.id, v]));

      let totalAmount = 0;
      const orderItemsData: any[] = [];

      for (const item of orderData.items) {
        const variant = variantMap.get(item.productVariantId);
        if (!variant) {
          throw new BadRequestException(
            `Product variant ${item.productVariantId} not found`,
          );
        }
        if (variant.stock < item.quantity) {
          throw new BadRequestException(
            `Insufficient stock for ${variant.productName}`,
          );
        }

        const itemTotal = Number(variant.price || 0) * item.quantity;
        totalAmount += itemTotal;

        orderItemsData.push({
          id: uuidv4(),
          orderId: '',
          productVariantId: variant.id,
          productName: variant.productName || 'Product',
          variantSku: variant.sku,
          colorName: variant.colorName,
          sizeName: variant.sizeName,
          quantity: item.quantity,
          unitPrice: variant.price || '0',
          totalPrice: itemTotal.toString(),
        });
      }

      const orderNumber = `ORD-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
      const shippingAddress = `${orderData.shippingAddress.fullAddress} (${orderData.shippingAddress.label}) - Phone: ${orderData.shippingAddress.phoneNumber}`;

      const [order] = await tx
        .insert(orders)
        .values({
          id: uuidv4(),
          orderNumber,
          userId,
          customerName: user.name || 'Customer',
          customerEmail: user.email || '',
          customerPhone: orderData.shippingAddress.phoneNumber,
          shippingAddress,
          totalAmount: totalAmount.toString(),
          status: 'PENDING',
          paymentMethod: orderData.paymentMethod,
          paymentStatus: 'PENDING',
          notes: orderData.notes,
        })
        .returning();

      orderItemsData.forEach((item) => (item.orderId = order.id));

      if (orderItemsData.length > 0) {
        await tx.insert(orderItems).values(orderItemsData);
      }

      for (const item of orderData.items) {
        await tx
          .update(productVariants)
          .set({ stock: sql`${productVariants.stock} - ${item.quantity}` })
          .where(eq(productVariants.id, item.productVariantId));
      }

      await tx.delete(cartItems).where(eq(cartItems.userId, userId));

      await tx.insert(notifications).values({
        id: uuidv4(),
        userId,
        type: 'order',
        title: 'Order Created',
        message: `Your order #${orderNumber} has been created successfully`,
        actionText: 'View Order',
        actionLink: `/orders/${order.id}`,
      });

      return { order, totalAmount, items: orderItemsData };
    });
  }

  // 🚀 SUPER OPTIMIZED: Drizzle Relational Query API
  // Fetches Orders -> Items -> Variants -> Products -> Images in ONE native SQL query!
  async getOrders(userId: string, status?: string) {
    const conditions = [eq(orders.userId, userId)];
    if (status) conditions.push(eq(orders.status, status));

    return this.drizzle.db.query.orders.findMany({
      where: and(...conditions),
      orderBy: [desc(orders.createdAt)],
      with: {
        items: {
          with: {
            variant: {
              with: {
                product: {
                  with: {
                    images: true, // 🚀 Automatically fetches product images!
                  },
                },
                color: true,
                size: true,
                image: true, // 🚀 Fetches variant-specific image if it exists
              },
            },
          },
        },
      },
    });
  }

  async getOrderById(orderId: string, userId: string) {
    const order = await this.drizzle.db.query.orders.findFirst({
      where: and(eq(orders.id, orderId), eq(orders.userId, userId)),
      with: {
        items: {
          with: {
            variant: {
              with: {
                product: {
                  with: {
                    images: true,
                  },
                },
                color: true,
                size: true,
                image: true,
              },
            },
          },
        },
      },
    });

    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  async updateOrderStatus(orderId: string, status: string) {
    const [order] = await this.drizzle.db
      .update(orders)
      .set({ status, updatedAt: new Date() })
      .where(eq(orders.id, orderId))
      .returning();

    if (!order) throw new NotFoundException('Order not found');

    await this.drizzle.db.insert(notifications).values({
      id: uuidv4(),
      userId: order.userId!,
      type: 'order',
      title: 'Order Status Updated',
      message: `Your order #${order.orderNumber} is now ${status.toLowerCase()}`,
      actionText: 'View Order',
      actionLink: `/orders/${order.id}`,
    });

    return order;
  }

  // ==========================================
  // NOTIFICATION MANAGEMENT
  // ==========================================

  async getUserNotifications(userId: string) {
    return this.drizzle.db
      .select()
      .from(notifications)
      .where(eq(notifications.userId, userId))
      .orderBy(desc(notifications.createdAt));
  }

  async markNotificationAsRead(notificationId: string, userId: string) {
    const [notification] = await this.drizzle.db
      .update(notifications)
      .set({ isRead: true })
      .where(
        and(
          eq(notifications.id, notificationId),
          eq(notifications.userId, userId),
        ),
      )
      .returning();

    if (!notification) throw new NotFoundException('Notification not found');
    return notification;
  }

  async markAllNotificationsAsRead(userId: string) {
    await this.drizzle.db
      .update(notifications)
      .set({ isRead: true })
      .where(eq(notifications.userId, userId));

    return { message: 'All notifications marked as read' };
  }

  async deleteNotification(notificationId: string, userId: string) {
    const [deleted] = await this.drizzle.db
      .delete(notifications)
      .where(
        and(
          eq(notifications.id, notificationId),
          eq(notifications.userId, userId),
        ),
      )
      .returning();

    if (!deleted) throw new NotFoundException('Notification not found');
    return { message: 'Notification deleted successfully' };
  }

  async getUnreadCount(userId: string) {
    const result = await this.drizzle.db
      .select({ count: sql<number>`count(*)` })
      .from(notifications)
      .where(
        and(eq(notifications.userId, userId), eq(notifications.isRead, false)),
      );

    return { unreadCount: Number(result[0]?.count) || 0 };
  }

  async createNotification(
    userId: string,
    type: string,
    title: string,
    message: string,
    actionText?: string,
    actionLink?: string,
  ) {
    const [notification] = await this.drizzle.db
      .insert(notifications)
      .values({
        id: uuidv4(),
        userId,
        type,
        title,
        message,
        actionText,
        actionLink,
      })
      .returning();

    return notification;
  }

  async processPayment(
    orderId: string,
    userId: string,
    paymentData: { paymentMethod: string; phoneNumber?: string },
  ) {
    const [order] = await this.drizzle.db
      .select()
      .from(orders)
      .where(and(eq(orders.id, orderId), eq(orders.userId, userId)));

    if (!order) throw new NotFoundException('Order not found');
    if (order.paymentStatus === 'PAID')
      throw new BadRequestException('Order is already paid');

    const transactionId = `TXN-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

    const [updatedOrder] = await this.drizzle.db
      .update(orders)
      .set({
        paymentStatus: 'PAID',
        status: 'CONFIRMED',
        updatedAt: new Date(),
      })
      .where(eq(orders.id, orderId))
      .returning();

    await this.createNotification(
      userId,
      'payment',
      'Payment Successful',
      `Payment for order #${order.orderNumber} was received successfully`,
      'View Order',
      `/orders/${order.id}`,
    );

    return {
      message: 'Payment processed successfully',
      transactionId,
      orderNumber: order.orderNumber,
      order: updatedOrder,
    };
  }
}
