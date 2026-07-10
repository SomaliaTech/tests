import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Inject,
  forwardRef,
  Logger,
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
import { eq, and, or, like, sql, desc, inArray } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';
import { CreateOrderDto } from './dto/create-order.dto';
import { AddressDto } from './dto/address.dto';
import { AddToCartDto } from '../products/dto/cart.dto';
import { ChatGateway } from '../chat/chat.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/notification.entity';

@Injectable()
export class OrdersService {
  private readonly logger = new Logger(OrdersService.name);

  constructor(
    private drizzle: DrizzleService,
    @Inject(forwardRef(() => ChatGateway))
    private chatGateway: ChatGateway,
    @Inject(forwardRef(() => NotificationsService))
    private notificationsService: NotificationsService,
  ) {}

  // ==========================================
  // ADDRESS MANAGEMENT
  // ==========================================

  async addAddress(userId: string, addressData: AddressDto) {
    this.logger.log(`Adding address for user: ${userId}`);

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
        label: addressData.label.trim(),
        fullAddress: addressData.fullAddress.trim(),
        phoneNumber: addressData.phoneNumber.trim(),
        isDefault: addressData.isDefault || false,
      })
      .returning();

    this.logger.log(`Address added: ${address.id}`);
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
  // CART MANAGEMENT
  // ==========================================
  async getCart(userId: string) {
    const userCartItems = await this.drizzle.db.query.cartItems.findMany({
      where: eq(cartItems.userId, userId),
      with: {
        variant: {
          with: {
            product: { with: { images: true } },
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

      // ✅ Handle case where variant is null
      const unitPrice = variant?.price
        ? Number(variant.price)
        : Number(product?.price || 0);
      const totalPrice = unitPrice * cartItem.quantity;
      subtotal += totalPrice;

      return {
        id: cartItem.id,
        productVariantId: cartItem.productVariantId, // This is null for non-variant products
        productId: product?.id || cartItem.productId,
        name: product?.name || 'Unknown Product',
        price: unitPrice,
        quantity: cartItem.quantity,
        totalPrice,
        inStock: (variant?.stock || product?.stock || 0) > 0,
        imageUrl: product?.images?.[0]?.url || '',
        color: variant?.color?.name || null,
        size: variant?.size?.name || null,
        // ✅ Add a flag to indicate if this has a variant
        hasVariant: cartItem.productVariantId !== null,
      };
    });

    return { items, subtotal, itemCount: items.length };
  }
  async addToCart(userId: string, dto: AddToCartDto) {
    const { productId, productVariantId, quantity } = dto;

    if (quantity < 1) {
      throw new BadRequestException('Quantity must be at least 1');
    }

    const product = await this.drizzle.db.query.products.findFirst({
      where: eq(products.id, productId),
    });
    if (!product) {
      throw new NotFoundException(`Product with ID ${productId} not found`);
    }

    let variant: any = null;
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

    // Check for existing cart item
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
    }

    const [newItem] = await this.drizzle.db
      .insert(cartItems)
      .values({
        id: uuidv4(),
        userId,
        productId,
        productVariantId: productVariantId || null,
        quantity,
      })
      .returning();
    return newItem;
  }

  async updateCartItem(userId: string, itemId: string, quantity: number) {
    if (quantity < 1) {
      throw new BadRequestException('Quantity must be at least 1');
    }

    const [existingItem] = await this.drizzle.db
      .select()
      .from(cartItems)
      .where(and(eq(cartItems.id, itemId), eq(cartItems.userId, userId)))
      .limit(1);

    if (!existingItem) throw new NotFoundException('Cart item not found');

    // Check stock
    if (existingItem.productVariantId) {
      const [variant] = await this.drizzle.db
        .select({ stock: productVariants.stock })
        .from(productVariants)
        .where(eq(productVariants.id, existingItem.productVariantId))
        .limit(1);
      if (variant && variant.stock < quantity) {
        throw new BadRequestException('Insufficient stock');
      }
    } else {
      const [product] = await this.drizzle.db
        .select({ stock: products.stock })
        .from(products)
        .where(eq(products.id, existingItem.productId))
        .limit(1);
      if (product && product.stock < quantity) {
        throw new BadRequestException('Insufficient stock');
      }
    }

    const [updated] = await this.drizzle.db
      .update(cartItems)
      .set({ quantity, updatedAt: new Date() })
      .where(eq(cartItems.id, itemId))
      .returning();

    if (!updated) throw new NotFoundException('Cart item not found');

    return updated;
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

  // ==========================================
  // ORDER MANAGEMENT
  // ==========================================
  // ==========================================
  // FAST ORDER MANAGEMENT
  // ==========================================

  async createOrder(userId: string, orderData: CreateOrderDto) {
    this.logger.log(`Creating order for user: ${userId}`);

    const result = await this.drizzle.db.transaction(async (tx) => {
      const [user] = await tx.select().from(users).where(eq(users.id, userId));
      if (!user) throw new NotFoundException('User not found');

      let totalAmount = 0;
      const orderItemsData: any[] = [];

      // Process items in parallel where possible
      for (const item of orderData.items) {
        if (item.productVariantId) {
          const [variant] = await tx
            .select({
              id: productVariants.id,
              price: productVariants.price,
              sku: productVariants.sku,
              stock: productVariants.stock,
              productId: productVariants.productId,
              productName: products.name,
              productStock: products.stock,
              productPrice: products.price,
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

          const availableStock =
            variant.stock > 0 ? variant.stock : (variant.productStock ?? 0);
          if (availableStock < item.quantity) {
            throw new BadRequestException(
              `Insufficient stock for ${variant.productName}`,
            );
          }

          const unitPrice = variant.price
            ? Number(variant.price)
            : Number(variant.productPrice ?? 0);
          totalAmount += unitPrice * item.quantity;

          orderItemsData.push({
            id: uuidv4(),
            orderId: '',
            productId: variant.productId,
            productVariantId: variant.id,
            productName: variant.productName || 'Product',
            variantSku: variant.sku,
            colorName: variant.colorName,
            sizeName: variant.sizeName,
            quantity: item.quantity,
            unitPrice: unitPrice.toString(),
            totalPrice: (unitPrice * item.quantity).toString(),
          });
        } else {
          const [product] = await tx
            .select()
            .from(products)
            .where(eq(products.id, item.productId))
            .limit(1);
          if (!product)
            throw new BadRequestException(
              `Product ${item.productId} not found`,
            );
          if (product.stock < item.quantity) {
            throw new BadRequestException(
              `Insufficient stock for ${product.name}`,
            );
          }

          const unitPrice = Number(product.price);
          totalAmount += unitPrice * item.quantity;

          orderItemsData.push({
            id: uuidv4(),
            orderId: '',
            productId: product.id,
            productVariantId: null,
            productName: product.name,
            variantSku: product.sku,
            colorName: null,
            sizeName: null,
            quantity: item.quantity,
            unitPrice: unitPrice.toString(),
            totalPrice: (unitPrice * item.quantity).toString(),
          });
        }
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

      // Batch insert order items
      orderItemsData.forEach((item) => (item.orderId = order.id));
      if (orderItemsData.length > 0) {
        await tx.insert(orderItems).values(orderItemsData);
      }

      // Deduct stock in parallel
      const stockUpdates = orderItemsData.map((item) => {
        if (item.productVariantId) {
          return tx
            .update(productVariants)
            .set({ stock: sql`${productVariants.stock} - ${item.quantity}` })
            .where(eq(productVariants.id, item.productVariantId));
        } else if (item.productId) {
          return tx
            .update(products)
            .set({ stock: sql`${products.stock} - ${item.quantity}` })
            .where(eq(products.id, item.productId));
        }
        return Promise.resolve();
      });
      await Promise.all(stockUpdates);

      // Clear cart
      await tx.delete(cartItems).where(eq(cartItems.userId, userId));

      // Notify admins inside transaction (fire and forget pattern)
      this._notifyAdminsNewOrder(tx, order, user.name || 'Customer').catch(
        () => {},
      );

      return { order, totalAmount, items: orderItemsData, user };
    });

    // ✅ FIRE AND FORGET - Don't await these! Return response immediately
    const { order, user } = result;

    // Fire-and-forget: WebSocket notification
    this.chatGateway.server.to(`user:${userId}`).emit('new_notification', {
      id: uuidv4(),
      type: 'order',
      title: 'Order Created',
      message: `Your order #${order.orderNumber} has been created`,
      actionText: 'View Order',
      actionLink: `/orders/${order.id}`,
      orderId: order.id,
      orderNumber: order.orderNumber,
      totalAmount: order.totalAmount,
      status: 'PENDING',
      createdAt: new Date().toISOString(),
      isRead: false,
    });

    // Fire-and-forget: Push notification
    this.notificationsService
      .create({
        userId,
        type: NotificationType.ORDER,
        title: 'Order Created',
        message: `Your order #${order.orderNumber} has been created`,
        actionText: 'View Order',
        actionLink: `/orders/${order.id}`,
      })
      .catch(() => {});

    // ✅ Return immediately without waiting for email/notifications
    return {
      order: result.order,
      totalAmount: result.totalAmount,
      items: result.items,
    };
  }

  // ==========================================
  // FAST PAYMENT PROCESSING
  // ==========================================
  async processPayment(
    orderId: string,
    userId: string,
    paymentData: { paymentMethod: string; phoneNumber?: string },
  ) {
    this.logger.log(`Processing payment for order: ${orderId}`);

    const [order] = await this.drizzle.db
      .select()
      .from(orders)
      .where(and(eq(orders.id, orderId), eq(orders.userId, userId)));

    if (!order) throw new NotFoundException('Order not found');
    if (order.paymentStatus === 'PAID') {
      throw new BadRequestException('Order is already paid');
    }

    const [updatedOrder] = await this.drizzle.db
      .update(orders)
      .set({
        paymentStatus: 'PAID',
        status: 'CONFIRMED',
        updatedAt: new Date(),
        paymentMethod: paymentData.paymentMethod,
      })
      .where(eq(orders.id, orderId))
      .returning();

    // ✅ Fire-and-forget notifications (don't block response)
    this.notificationsService
      .create({
        userId,
        type: NotificationType.PAYMENT,
        title: 'Payment Successful',
        message: `Payment for order #${order.orderNumber} was received`,
        actionText: 'View Order',
        actionLink: `/orders/${order.id}`,
      })
      .catch(() => {});

    // ✅ Return immediately
    return {
      message: 'Payment processed successfully',
      transactionId: `TXN-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
      orderNumber: order.orderNumber,
      order: updatedOrder,
    };
  }
  async getOrders(
    userId: string,
    status?: string,
    page: number = 1,
    limit: number = 10,
  ) {
    const offset = (page - 1) * limit;
    const conditions = [eq(orders.userId, userId)];
    if (status) conditions.push(eq(orders.status, status));

    const whereClause = and(...conditions);

    const [items, total] = await Promise.all([
      this.drizzle.db.query.orders.findMany({
        where: whereClause,
        orderBy: [desc(orders.createdAt)],
        limit: Math.min(limit, 50),
        offset,
        with: {
          items: {
            with: {
              variant: {
                with: {
                  product: { with: { images: true } },
                  color: true,
                  size: true,
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

  async getOrderById(orderId: string, userId: string) {
    const order = await this.drizzle.db.query.orders.findFirst({
      where: and(eq(orders.id, orderId), eq(orders.userId, userId)),
      with: {
        items: {
          with: {
            variant: {
              with: {
                product: { with: { images: true } },
                color: true,
                size: true,
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
    this.logger.log(`Updating order ${orderId} status to ${status}`);

    const [order] = await this.drizzle.db
      .update(orders)
      .set({ status, updatedAt: new Date() })
      .where(eq(orders.id, orderId))
      .returning();

    if (!order) throw new NotFoundException('Order not found');

    // Send notification to user
    if (order.userId) {
      // Get user email if needed
      const [user] = await this.drizzle.db
        .select({ email: users.email, name: users.name })
        .from(users)
        .where(eq(users.id, order.userId))
        .limit(1);

      await this.notificationsService.create({
        userId: order.userId,
        type: NotificationType.ORDER,
        title: 'Order Status Updated',
        message: `Your order #${order.orderNumber} is now ${status.toLowerCase()}`,
        actionText: 'View Order',
        actionLink: `/orders/${order.id}`,
      });

      // Also notify all admins
      await this._notifyAdminsStatusChange(order, status);

      // ✅ Send shipping update email if user has email
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

  // ==========================================
  // PRIVATE HELPERS
  // ==========================================

  private async _notifyAdminsNewOrder(
    tx: any,
    order: any,
    customerName: string,
  ) {
    try {
      const admins = await tx
        .select({ id: users.id, email: users.email, name: users.name })
        .from(users)
        .where(or(eq(users.isAdmin, true), eq(users.isSuperAdmin, true)));

      const notificationTitle = 'New Order Received';
      const notificationMessage = `New order #${order.orderNumber} from ${customerName} - $${order.totalAmount}`;

      for (const admin of admins) {
        // Save notification to DB
        await tx.insert(notifications).values({
          id: uuidv4(),
          userId: admin.id,
          type: 'order',
          title: notificationTitle,
          message: notificationMessage,
          actionText: 'View Order',
          actionLink: `/admin/orders/${order.id}`,
        });

        // Send email to admin (fire and forget)
      }

      // WebSocket to admin room
      this.chatGateway.server.to('admins').emit('new_notification', {
        id: uuidv4(),
        type: 'order',
        title: notificationTitle,
        message: notificationMessage,
        actionText: 'View Orders',
        actionLink: '/admin/orders',
        orderId: order.id,
        orderNumber: order.orderNumber,
        totalAmount: order.totalAmount,
        customerName: customerName,
        createdAt: new Date().toISOString(),
        isRead: false,
      });

      this.logger.log(`📧 Admin notifications sent to ${admins.length} admins`);
    } catch (error) {
      this.logger.warn('Failed to notify admins:', error);
    }
  }
  private async _notifyAdminsStatusChange(order: any, status: string) {
    try {
      const admins = await this.drizzle.db
        .select({ id: users.id })
        .from(users)
        .where(or(eq(users.isAdmin, true), eq(users.isSuperAdmin, true)));

      for (const admin of admins) {
        if (admin.id !== order.userId) {
          await this.notificationsService.create({
            userId: admin.id,
            type: NotificationType.ORDER,
            title: 'Order Status Changed',
            message: `Order #${order.orderNumber} changed to ${status.toLowerCase()}`,
            actionText: 'View Order',
            actionLink: `/admin/orders/${order.id}`,
          });
        }
      }
    } catch (error) {
      this.logger.warn('Failed to notify admins of status change:', error);
    }
  }
}
