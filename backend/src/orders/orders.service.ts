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
import { AddToCartDto } from '../products/dto/cart.dto';

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
  // ORDER MANAGEMENT
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
  }

  async getOrderById(orderId: string, userId: string) {
    const uuidRegex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(orderId)) {
      throw new NotFoundException('Invalid order ID format');
    }

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

  // ==========================================
  // CART MANAGEMENT
  // ==========================================
  // CART MANAGEMENT
  // ==========================================

  async getCart(userId: string) {
    const userCartItems = await this.drizzle.db.query.cartItems.findMany({
      where: eq(cartItems.userId, userId),
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
          },
        },
      },
    });

    let subtotal = 0;
    const items = userCartItems.map((cartItem) => {
      const variant = cartItem.variant;
      const product = variant?.product;

      const unitPrice = variant?.price
        ? Number(variant.price)
        : Number(product?.price || 0);
      const totalPrice = unitPrice * cartItem.quantity;
      subtotal += totalPrice;

      return {
        id: cartItem.id,
        productVariantId: cartItem.productVariantId,
        productId: product?.id || '',
        name: product?.name || 'Unknown Product',
        price: unitPrice,
        quantity: cartItem.quantity,
        totalPrice,
        inStock: (variant?.stock || 0) > 0,
        imageUrl: product?.images?.[0]?.url || '',
        color: variant?.color?.name || null,
        size: variant?.size?.name || null,
      };
    });

    return {
      items,
      subtotal,
      itemCount: items.length,
    };
  }

  async addToCart(userId: string, dto: AddToCartDto) {
    const { productId, productVariantId, quantity } = dto;

    // Validate product exists
    const product = await this.drizzle.db.query.products.findFirst({
      where: eq(products.id, productId),
    });

    if (!product) {
      throw new NotFoundException(`Product with ID ${productId} not found`);
    }

    let variant: any = null; // ✅ FIXED: Use 'any' to avoid type issues
    if (productVariantId) {
      variant = await this.drizzle.db.query.productVariants.findFirst({
        where: and(
          eq(productVariants.id, productVariantId),
          eq(productVariants.productId, productId),
        ),
      });

      if (!variant) {
        throw new NotFoundException(
          `Variant with ID ${productVariantId} not found`,
        );
      }

      if (variant.stock < quantity) {
        throw new BadRequestException('Insufficient stock');
      }
    }

    // Check if item already exists in cart
    const [existingItem] = await this.drizzle.db
      .select()
      .from(cartItems)
      .where(
        and(
          eq(cartItems.userId, userId),
          eq(cartItems.productId, productId),
          productVariantId
            ? eq(cartItems.productVariantId, productVariantId)
            : sql`${cartItems.productVariantId} IS NULL`,
        ),
      )
      .limit(1);

    if (existingItem) {
      const [updated] = await this.drizzle.db
        .update(cartItems)
        .set({
          quantity: existingItem.quantity + quantity,
          updatedAt: new Date(),
        })
        .where(eq(cartItems.id, existingItem.id))
        .returning();
      return updated;
    } else {
      const [newItem] = await this.drizzle.db
        .insert(cartItems)
        .values({
          id: uuidv4(),
          userId,
          productId,
          productVariantId: productVariantId || null,
          quantity,
          createdAt: new Date(),
          updatedAt: new Date(),
        })
        .returning();
      return newItem;
    }
  }
  async removeCartItem(userId: string, itemId: string) {
    const [deleted] = await this.drizzle.db
      .delete(cartItems)
      .where(and(eq(cartItems.id, itemId), eq(cartItems.userId, userId)))
      .returning();

    if (!deleted) throw new NotFoundException('Cart item not found');
    return { message: 'Item removed from cart' };
  }

  async clearCart(userId: string) {
    await this.drizzle.db.delete(cartItems).where(eq(cartItems.userId, userId));
    return { message: 'Cart cleared successfully' };
  }

  async updateCartItem(userId: string, itemId: string, quantity: number) {
    const [existingItem] = await this.drizzle.db
      .select()
      .from(cartItems)
      .where(and(eq(cartItems.id, itemId), eq(cartItems.userId, userId)))
      .limit(1);

    if (!existingItem) {
      throw new NotFoundException('Cart item not found');
    }

    // Check stock availability
    if (existingItem.productVariantId) {
      const [variant] = await this.drizzle.db
        .select()
        .from(productVariants)
        .where(eq(productVariants.id, existingItem.productVariantId))
        .limit(1);

      if (variant && variant.stock < quantity) {
        throw new BadRequestException('Insufficient stock');
      }
    } else {
      // ✅ FIXED: Use existingItem.productId (non-nullable in schema)
      const [product] = await this.drizzle.db
        .select()
        .from(products)
        .where(eq(products.id, existingItem.productId as string))
        .limit(1);

      if (product && product.stock < quantity) {
        throw new BadRequestException('Insufficient stock');
      }
    }

    const [updated] = await this.drizzle.db
      .update(cartItems)
      .set({
        quantity,
        updatedAt: new Date(),
      })
      .where(eq(cartItems.id, itemId))
      .returning();

    if (!updated) throw new NotFoundException('Cart item not found');

    // ✅ FIXED: Use existingItem.productId with type assertion
    const product = await this.drizzle.db
      .select()
      .from(products)
      .where(eq(products.id, existingItem.productId as string))
      .limit(1);

    return {
      id: updated.id,
      productId: product[0].id,
      productVariantId: updated.productVariantId,
      name: product[0].name,
      imageUrl: '',
      price: Number(product[0].price),
      quantity: updated.quantity,
      totalPrice: Number(product[0].price) * updated.quantity,
      inStock: true,
    };
  }
}
