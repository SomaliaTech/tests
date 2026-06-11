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
// Added inArray for batch fetching
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
    // 🚀 OPTIMIZATION 1: Wrap everything in a Database Transaction.
    // This ensures data integrity (if stock update fails, order isn't created)
    // and drastically improves performance by committing once at the end.
    return this.drizzle.db.transaction(async (tx) => {
      // 1. Get user details
      const [user] = await tx.select().from(users).where(eq(users.id, userId));
      if (!user) throw new NotFoundException('User not found');

      // 🚀 OPTIMIZATION 2: Fetch ALL variants in ONE single query instead of looping
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
        .where(inArray(productVariants.id, variantIds)); // Fetch all at once!

      // Map variants for O(1) lookups
      const variantMap = new Map(variants.map((v) => [v.id, v]));

      let totalAmount = 0;
      const orderItemsData: any[] = [];

      // 2. Validate stock and calculate totals
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

        // Prepare data for batch insert
        orderItemsData.push({
          id: uuidv4(),
          orderId: '', // Will be populated after order creation
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

      // 3. Create Order
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

      // 4. Assign Order ID to items
      orderItemsData.forEach((item) => (item.orderId = order.id));

      // 🚀 OPTIMIZATION 3: Batch insert all order items in ONE query
      if (orderItemsData.length > 0) {
        await tx.insert(orderItems).values(orderItemsData);
      }

      // 5. Update stock (Inside the transaction, this is lightning fast)
      for (const item of orderData.items) {
        await tx
          .update(productVariants)
          .set({ stock: sql`${productVariants.stock} - ${item.quantity}` })
          .where(eq(productVariants.id, item.productVariantId));
      }

      // 6. Clear user's cart
      await tx.delete(cartItems).where(eq(cartItems.userId, userId));

      // 7. Create notification
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

  async getOrders(userId: string, status?: string) {
    const conditions = [eq(orders.userId, userId)];
    if (status) conditions.push(eq(orders.status, status));

    const userOrders = await this.drizzle.db
      .select()
      .from(orders)
      .where(and(...conditions))
      .orderBy(desc(orders.createdAt));

    if (userOrders.length === 0) return [];

    // 🚀 OPTIMIZATION 4: Fix N+1 problem.
    // Fetch ALL items for ALL orders in ONE single query instead of looping.
    const orderIds = userOrders.map((o) => o.id);
    const allItems = await this.drizzle.db
      .select()
      .from(orderItems)
      .where(inArray(orderItems.orderId, orderIds));

    // Group items by orderId in memory
    const itemsMap = new Map<string, typeof allItems>();
    for (const item of allItems) {
      if (!itemsMap.has(item.orderId)) itemsMap.set(item.orderId, []);
      itemsMap.get(item.orderId)!.push(item);
    }

    // Map items back to orders
    return userOrders.map((order) => ({
      ...order,
      items: itemsMap.get(order.id) || [],
    }));
  }

  async getOrderById(orderId: string, userId: string) {
    const [order] = await this.drizzle.db
      .select()
      .from(orders)
      .where(and(eq(orders.id, orderId), eq(orders.userId, userId)));

    if (!order) throw new NotFoundException('Order not found');

    const items = await this.drizzle.db
      .select()
      .from(orderItems)
      .where(eq(orderItems.orderId, order.id));

    return { ...order, items };
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
  // ==========================================
  // NOTIFICATION HELPER
  // ==========================================

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

  // ADD THIS METHOD to your OrdersService class
  async processPayment(
    orderId: string,
    userId: string,
    paymentData: { paymentMethod: string; phoneNumber?: string },
  ) {
    // 1. Verify the order exists and belongs to this user
    const [order] = await this.drizzle.db
      .select()
      .from(orders)
      .where(and(eq(orders.id, orderId), eq(orders.userId, userId)));

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    if (order.paymentStatus === 'PAID') {
      throw new BadRequestException('Order is already paid');
    }

    // ==========================================
    // 2. TODO: INTEGRATE YOUR PAYMENT GATEWAY HERE
    // ==========================================
    // For EVC Plus, Zaad, etc., you would typically make an HTTP request
    // to the telecom provider's API or a payment aggregator (like Paystack/Stripe).
    // If the gateway uses webhooks, you would set the status to 'PROCESSING' here.
    // For now, we simulate an immediate successful payment.

    const transactionId = `TXN-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

    // 3. Update the order status in the database
    const [updatedOrder] = await this.drizzle.db
      .update(orders)
      .set({
        paymentStatus: 'PAID', // Change to 'PROCESSING' if your gateway uses async webhooks
        status: 'CONFIRMED', // Change to 'PROCESSING' if needed
        updatedAt: new Date(),
      })
      .where(eq(orders.id, orderId))
      .returning();

    // 4. Create a notification for the user
    await this.createNotification(
      userId,
      'payment',
      'Payment Successful',
      `Payment for order #${order.orderNumber} was received successfully`,
      'View Order',
      `/orders/${order.id}`,
    );

    // 5. Return the result to Flutter
    return {
      message: 'Payment processed successfully',
      transactionId,
      orderNumber: order.orderNumber,
      order: updatedOrder,
    };
  }
}
