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
import { eq, and, sql, desc } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';
import { CreateOrderDto, AddressDto } from './dto/create-order.dto';

export interface OrderItemData {
  variant: {
    id: string;
    price: string | null;
    sku: string;
    stock: number;
    productId: string;
    productName: string | null;
    colorName: string | null;
    sizeName: string | null;
  };
  quantity: number;
  totalPrice: number;
}

@Injectable()
export class OrdersService {
  constructor(private drizzle: DrizzleService) {}

  // ==========================================
  // ADDRESS MANAGEMENT
  // ==========================================

  async addAddress(userId: string, addressData: AddressDto) {
    // If this is the first address or marked as default, unset other defaults
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
    // Unset all default addresses for this user
    await this.drizzle.db
      .update(addresses)
      .set({ isDefault: false })
      .where(eq(addresses.userId, userId));

    // Set the selected address as default
    const [address] = await this.drizzle.db
      .update(addresses)
      .set({ isDefault: true })
      .where(and(eq(addresses.id, addressId), eq(addresses.userId, userId)))
      .returning();

    if (!address) {
      throw new NotFoundException('Address not found');
    }

    return address;
  }

  async deleteAddress(userId: string, addressId: string) {
    const [deleted] = await this.drizzle.db
      .delete(addresses)
      .where(and(eq(addresses.id, addressId), eq(addresses.userId, userId)))
      .returning();

    if (!deleted) {
      throw new NotFoundException('Address not found');
    }

    return { message: 'Address deleted successfully' };
  }

  // ==========================================
  // ORDER MANAGEMENT
  // ==========================================

  async createOrder(userId: string, orderData: CreateOrderDto) {
    // Get user details
    const [user] = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.id, userId));

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Calculate total amount and validate products
    let totalAmount = 0;
    const orderItemsData: OrderItemData[] = [];

    for (const item of orderData.items) {
      const [variant] = await this.drizzle.db
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
        .where(eq(productVariants.id, item.productVariantId))
        .limit(1);

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

      const itemTotal = Number(variant.price) * item.quantity;
      totalAmount += itemTotal;

      orderItemsData.push({
        variant: {
          id: variant.id,
          price: variant.price,
          sku: variant.sku,
          stock: variant.stock,
          productId: variant.productId,
          productName: variant.productName,
          colorName: variant.colorName,
          sizeName: variant.sizeName,
        },
        quantity: item.quantity,
        totalPrice: itemTotal,
      });
    }

    // Create order
    const orderNumber = `ORD-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const shippingAddress = `${orderData.shippingAddress.fullAddress} (${orderData.shippingAddress.label}) - Phone: ${orderData.shippingAddress.phoneNumber}`;

    const [order] = await this.drizzle.db
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

    // Create order items and update stock
    for (const item of orderItemsData) {
      await this.drizzle.db.insert(orderItems).values({
        id: uuidv4(),
        orderId: order.id,
        productVariantId: item.variant.id,
        productName: item.variant.productName || 'Product',
        variantSku: item.variant.sku,
        colorName: item.variant.colorName,
        sizeName: item.variant.sizeName,
        quantity: item.quantity,
        unitPrice: item.variant.price || '0',
        totalPrice: item.totalPrice.toString(),
      });

      // Update stock
      await this.drizzle.db
        .update(productVariants)
        .set({ stock: sql`${productVariants.stock} - ${item.quantity}` })
        .where(eq(productVariants.id, item.variant.id));
    }

    // Clear user's cart after order creation
    await this.drizzle.db.delete(cartItems).where(eq(cartItems.userId, userId));

    // Create notification for order created
    await this.createNotification(
      userId,
      'order',
      'Order Created',
      `Your order #${orderNumber} has been created successfully`,
      'View Order',
      `/orders/${order.id}`,
    );

    return {
      order,
      totalAmount,
      items: orderItemsData,
    };
  }

  async getOrders(userId: string, status?: string) {
    const conditions = [eq(orders.userId, userId)];

    if (status) {
      conditions.push(eq(orders.status, status));
    }

    const userOrders = await this.drizzle.db
      .select()
      .from(orders)
      .where(and(...conditions))
      .orderBy(desc(orders.createdAt));

    // Get items for each order
    const ordersWithItems = await Promise.all(
      userOrders.map(async (order) => {
        const items = await this.drizzle.db
          .select()
          .from(orderItems)
          .where(eq(orderItems.orderId, order.id));
        return { ...order, items };
      }),
    );

    return ordersWithItems;
  }

  async getOrderById(orderId: string, userId: string) {
    const [order] = await this.drizzle.db
      .select()
      .from(orders)
      .where(and(eq(orders.id, orderId), eq(orders.userId, userId)));

    if (!order) {
      throw new NotFoundException('Order not found');
    }

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

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    // Create notification for status update
    await this.createNotification(
      order.userId!,
      'order',
      'Order Status Updated',
      `Your order #${order.orderNumber} is now ${status.toLowerCase()}`,
      'View Order',
      `/orders/${order.id}`,
    );

    return order;
  }

  // ==========================================
  // NOTIFICATION MANAGEMENT
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

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

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

    if (!deleted) {
      throw new NotFoundException('Notification not found');
    }

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
}
