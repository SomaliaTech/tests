// src/orders/orders.service.ts

import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Inject,
  forwardRef,
  Logger,
  ForbiddenException,
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
import { WaafiPayService } from '../payment/waafipay.service';
import { LogSanitizer } from '../common/utils/log-sanitizer.util';
import {
  OrderStatus,
  PaymentStatus,
  ORDER_STATUS_TRANSITIONS,
  FINAL_ORDER_STATUSES,
} from './enums/order-status.enum';

@Injectable()
export class OrdersService {
  private readonly logger = new Logger(OrdersService.name);

  constructor(
    private drizzle: DrizzleService,
    @Inject(forwardRef(() => ChatGateway))
    private chatGateway: ChatGateway,
    @Inject(forwardRef(() => NotificationsService))
    private notificationsService: NotificationsService,
    private waafiPayService: WaafiPayService,
  ) {}

  // ==========================================
  // CREATE ORDER WITH PAYMENT VALIDATION
  // ==========================================

  async createOrder(userId: string, orderData: CreateOrderDto) {
    this.logger.log(
      `Processing order for user: ${LogSanitizer.maskValue(userId)}`,
    );

    const { itemsTotal, orderItemsData, user, deliveryFee, finalTotalAmount } =
      await this._validateAndPrepareOrder(userId, orderData);

    const paymentResult = await this._processPaymentIfNeeded(
      orderData,
      finalTotalAmount,
    );

    const result = await this.drizzle.db.transaction(async (tx) => {
      const orderNumber = `ORD-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
      const shippingAddress = `${orderData.shippingAddress.fullAddress} (${orderData.shippingAddress.label}) - Phone: ${orderData.shippingAddress.phoneNumber}`;

      const isPaid = paymentResult?.success === true;
      const initialStatus = isPaid
        ? OrderStatus.CONFIRMED
        : OrderStatus.PENDING;
      const initialPaymentStatus = isPaid
        ? PaymentStatus.PAID
        : PaymentStatus.PENDING;

      // ✅ FIX: Use correct field names that exist in schema
      const [order] = await tx
        .insert(orders)
        .values({
          id: uuidv4(),
          orderNumber: orderNumber,
          userId: userId,
          customerName: user.name || 'Customer',
          customerEmail: user.email || '',
          customerPhone: orderData.shippingAddress.phoneNumber,
          shippingAddress: shippingAddress,
          totalAmount: finalTotalAmount.toString(),
          status: initialStatus,
          paymentMethod: orderData.paymentMethod,
          paymentStatus: initialPaymentStatus,
          paymentReferenceId: paymentResult?.transactionId || null,
          notes: orderData.notes || null,
        })
        .returning();

      orderItemsData.forEach((item) => (item.orderId = order.id));
      if (orderItemsData.length > 0) {
        await tx.insert(orderItems).values(orderItemsData);
      }

      await this._updateStock(tx, orderItemsData);
      await tx.delete(cartItems).where(eq(cartItems.userId, userId));

      this._notifyAdminsNewOrder(tx, order, user.name || 'Customer').catch(
        () => {},
      );

      return {
        order,
        totalAmount: finalTotalAmount,
        items: orderItemsData,
        user,
        paymentResult,
      };
    });

    await this._sendOrderNotifications(result.order, result.user);

    return {
      order: result.order,
      totalAmount: result.totalAmount,
      items: result.items,
      payment: result.paymentResult,
      message:
        result.order.paymentStatus === PaymentStatus.PAID
          ? 'Order created and payment processed successfully'
          : 'Order created successfully. Please complete payment.',
    };
  }

  // ==========================================
  // VALIDATE AND PREPARE ORDER
  // ==========================================

  private async _validateAndPrepareOrder(
    userId: string,
    orderData: CreateOrderDto,
  ) {
    let itemsTotal = 0;
    const orderItemsData: any[] = [];

    const [user] = await this.drizzle.db
      .select()
      .from(users)
      .where(eq(users.id, userId));

    if (!user) throw new NotFoundException('User not found');

    for (const item of orderData.items) {
      if (item.productVariantId) {
        const [variant] = await this.drizzle.db
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
        itemsTotal += unitPrice * item.quantity;

        orderItemsData.push({
          id: uuidv4(),
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
        const [product] = await this.drizzle.db
          .select()
          .from(products)
          .where(eq(products.id, item.productId))
          .limit(1);

        if (!product)
          throw new BadRequestException(`Product ${item.productId} not found`);
        if (product.stock < item.quantity) {
          throw new BadRequestException(
            `Insufficient stock for ${product.name}`,
          );
        }

        const unitPrice = Number(product.price);
        itemsTotal += unitPrice * item.quantity;

        orderItemsData.push({
          id: uuidv4(),
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

    const deliveryFee = orderData.deliveryFee ?? 0;
    const finalTotalAmount = itemsTotal + deliveryFee;

    this.logger.log(
      `💰 Order total: Items=${itemsTotal}, Delivery=${deliveryFee}, Final=${finalTotalAmount}`,
    );

    return { itemsTotal, orderItemsData, user, deliveryFee, finalTotalAmount };
  }

  // ==========================================
  // PROCESS PAYMENT IF NEEDED
  // ==========================================

  private async _processPaymentIfNeeded(
    orderData: CreateOrderDto,
    finalTotalAmount: number,
  ) {
    if (orderData.paymentMethod === 'cash_on_delivery') {
      this.logger.log('💰 Cash on delivery - no payment processing needed');
      return { success: true, message: 'Cash on delivery' };
    }

    if (!orderData.paymentMethod || !orderData.phoneNumber) {
      this.logger.log('💰 No payment method or phone - skipping payment');
      return { success: false, message: 'Payment method not provided' };
    }

    this.logger.log(`🔄 Processing payment for order...`);

    const paymentRefId = this.waafiPayService.generateReferenceId(
      `ORDER-${Date.now()}`,
    );

    const paymentResult = await this.waafiPayService.initiatePayment({
      amount: finalTotalAmount,
      phoneNumber: orderData.phoneNumber,
      orderId: `INV-${Date.now()}`,
      description: `Payment for order via ${orderData.paymentMethod}`,
      referenceId: paymentRefId,
      paymentMethod: orderData.paymentMethod,
    });

    if (!paymentResult.success) {
      this.logger.error(`❌ Payment failed: ${paymentResult.message}`);
      throw new BadRequestException(
        paymentResult.message || 'Payment failed. Please try again.',
      );
    }

    this.logger.log(
      `✅ Payment successful! Transaction: ${paymentResult.transactionId}`,
    );

    return paymentResult;
  }

  // ==========================================
  // UPDATE ORDER STATUS WITH STATE VALIDATION
  // ==========================================

  async updateOrderStatus(orderId: string, newStatus: OrderStatus) {
    this.logger.log(`Updating order ${orderId} status to ${newStatus}`);

    const [order] = await this.drizzle.db
      .select()
      .from(orders)
      .where(eq(orders.id, orderId))
      .limit(1);

    if (!order) throw new NotFoundException('Order not found');

    const allowedTransitions =
      ORDER_STATUS_TRANSITIONS[order.status as OrderStatus] || [];
    if (!allowedTransitions.includes(newStatus)) {
      throw new BadRequestException(
        `Cannot transition order from '${order.status}' to '${newStatus}'. ` +
          `Allowed transitions: ${allowedTransitions.join(', ') || 'none'}`,
      );
    }

    if (
      newStatus === OrderStatus.CONFIRMED &&
      order.paymentStatus !== PaymentStatus.PAID
    ) {
      if (order.paymentMethod !== 'cash_on_delivery') {
        throw new BadRequestException(
          'Cannot confirm order. Payment must be completed first.',
        );
      }
    }

    if (
      newStatus === OrderStatus.SHIPPED &&
      order.paymentStatus !== PaymentStatus.PAID
    ) {
      throw new BadRequestException(
        'Cannot ship order. Payment must be completed first.',
      );
    }

    if (FINAL_ORDER_STATUSES.includes(order.status as OrderStatus)) {
      throw new BadRequestException(
        `Order is already in final state '${order.status}'. Cannot change.`,
      );
    }

    // ✅ FIX: Only include fields that exist in schema
    const updateData: any = {
      status: newStatus,
      updatedAt: new Date(),
    };

    if ([OrderStatus.DELIVERED, OrderStatus.CANCELLED].includes(newStatus)) {
      updateData.completedAt = new Date();
    }

    const [updatedOrder] = await this.drizzle.db
      .update(orders)
      .set(updateData)
      .where(eq(orders.id, orderId))
      .returning();

    await this._sendStatusUpdateNotifications(updatedOrder, newStatus);

    return {
      message: `Order status updated from '${order.status}' to '${newStatus}'`,
      order: {
        id: updatedOrder.id,
        orderNumber: updatedOrder.orderNumber,
        status: updatedOrder.status,
        paymentStatus: updatedOrder.paymentStatus,
      },
    };
  }

  // ==========================================
  // UPDATE PAYMENT STATUS
  // ==========================================

  async updatePaymentStatus(orderId: string, paymentStatus: PaymentStatus) {
    const validStatuses = Object.values(PaymentStatus);
    if (!validStatuses.includes(paymentStatus)) {
      throw new BadRequestException(
        `Invalid payment status. Allowed: ${validStatuses.join(', ')}`,
      );
    }

    const [order] = await this.drizzle.db
      .select()
      .from(orders)
      .where(eq(orders.id, orderId))
      .limit(1);

    if (!order) throw new NotFoundException('Order not found');

    const updates: any = {
      paymentStatus: paymentStatus,
      updatedAt: new Date(),
    };

    if (
      paymentStatus === PaymentStatus.PAID &&
      order.status === OrderStatus.PENDING
    ) {
      updates.status = OrderStatus.CONFIRMED;
    }

    const [updatedOrder] = await this.drizzle.db
      .update(orders)
      .set(updates)
      .where(eq(orders.id, orderId))
      .returning();

    if (!updatedOrder) throw new NotFoundException('Order not found');

    if (paymentStatus === PaymentStatus.PAID) {
      // ✅ FIX: Check if userId exists before sending notification
      if (updatedOrder.userId) {
        await this.notificationsService.create({
          userId: updatedOrder.userId,
          type: NotificationType.PAYMENT,
          title: 'Payment Successful',
          message: `Payment for order #${updatedOrder.orderNumber} was received`,
          actionText: 'View Order',
          actionLink: `/orders/${orderId}`,
        });
      }
    }

    return {
      message: `Payment status updated to '${paymentStatus}'`,
      order: {
        id: updatedOrder.id,
        orderNumber: updatedOrder.orderNumber,
        paymentStatus: updatedOrder.paymentStatus,
        status: updatedOrder.status,
      },
    };
  }

  // ==========================================
  // CANCEL ORDER WITH VALIDATION
  // ==========================================

  async cancelOrder(orderId: string, userId: string, reason?: string) {
    const [order] = await this.drizzle.db
      .select()
      .from(orders)
      .where(and(eq(orders.id, orderId), eq(orders.userId, userId)))
      .limit(1);

    if (!order) throw new NotFoundException('Order not found');

    const CANCELLABLE_STATUSES = [
      OrderStatus.PENDING,
      OrderStatus.CONFIRMED,
      OrderStatus.PROCESSING,
    ];
    if (!CANCELLABLE_STATUSES.includes(order.status as OrderStatus)) {
      throw new BadRequestException(
        `Cannot cancel order in '${order.status}' status. ` +
          `Only orders in ${CANCELLABLE_STATUSES.join(', ')} can be cancelled.`,
      );
    }

    // ✅ FIX: Use proper typing for refundResult
    let refundResult: { success: boolean; message: string } | null = null;

    // ✅ FIX: Check if paymentReferenceId exists on order
    if (
      order.paymentStatus === PaymentStatus.PAID &&
      (order as any).paymentReferenceId
    ) {
      this.logger.log(`Processing refund for order ${orderId}`);
      refundResult = { success: true, message: 'Refund initiated' };
    }

    // ✅ FIX: Only include fields that exist in schema
    const updateData: any = {
      status: OrderStatus.CANCELLED,
      updatedAt: new Date(),
    };

    if (reason) {
      updateData.notes = `${order.notes || ''}\nCancellation reason: ${reason}`;
    }

    const [cancelledOrder] = await this.drizzle.db
      .update(orders)
      .set(updateData)
      .where(eq(orders.id, orderId))
      .returning();

    await this._restoreStock(orderId);

    // ✅ FIX: Check if userId exists before sending notification
    if (cancelledOrder.userId) {
      await this.notificationsService.create({
        userId: cancelledOrder.userId,
        type: NotificationType.ORDER,
        title: 'Order Cancelled',
        message: `Your order #${order.orderNumber} has been cancelled.${reason ? ` Reason: ${reason}` : ''}`,
        actionText: 'View Order',
        actionLink: `/orders/${orderId}`,
      });
    }

    return {
      message: 'Order cancelled successfully',
      order: cancelledOrder,
      refund: refundResult,
    };
  }

  // ==========================================
  // PRIVATE HELPERS
  // ==========================================

  private async _updateStock(tx: any, orderItemsData: any[]) {
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
  }

  private async _restoreStock(orderId: string) {
    const items = await this.drizzle.db
      .select()
      .from(orderItems)
      .where(eq(orderItems.orderId, orderId));

    for (const item of items) {
      if (item.productVariantId) {
        await this.drizzle.db
          .update(productVariants)
          .set({ stock: sql`${productVariants.stock} + ${item.quantity}` })
          .where(eq(productVariants.id, item.productVariantId));
      } else if (item.productId) {
        await this.drizzle.db
          .update(products)
          .set({ stock: sql`${products.stock} + ${item.quantity}` })
          .where(eq(products.id, item.productId));
      }
    }
  }

  private async _sendOrderNotifications(order: any, user: any) {
    // ✅ FIX: Check if userId exists
    if (order.userId) {
      this.chatGateway.server
        .to(`user:${order.userId}`)
        .emit('new_notification', {
          id: uuidv4(),
          type: 'order',
          title: 'Order Created',
          message: `Your order #${order.orderNumber} has been created`,
          actionText: 'View Order',
          actionLink: `/orders/${order.id}`,
          orderId: order.id,
          orderNumber: order.orderNumber,
          totalAmount: order.totalAmount,
          status: order.status,
          createdAt: new Date().toISOString(),
          isRead: false,
        });

      await this.notificationsService.create({
        userId: order.userId,
        type: NotificationType.ORDER,
        title: 'Order Created',
        message: `Your order #${order.orderNumber} has been created`,
        actionText: 'View Order',
        actionLink: `/orders/${order.id}`,
      });

      if (order.paymentStatus === PaymentStatus.PAID) {
        await this.notificationsService.create({
          userId: order.userId,
          type: NotificationType.PAYMENT,
          title: 'Payment Successful',
          message: `Payment for order #${order.orderNumber} was received`,
          actionText: 'View Order',
          actionLink: `/orders/${order.id}`,
        });
      }
    }
  }

  private async _sendStatusUpdateNotifications(
    order: any,
    newStatus: OrderStatus,
  ) {
    // ✅ FIX: Check if userId exists
    if (order.userId) {
      await this.notificationsService.create({
        userId: order.userId,
        type: NotificationType.ORDER,
        title: 'Order Status Updated',
        message: `Your order #${order.orderNumber} is now ${newStatus.toLowerCase()}`,
        actionText: 'View Order',
        actionLink: `/orders/${order.id}`,
      });

      this.chatGateway.server
        .to(`user:${order.userId}`)
        .emit('order_status_update', {
          orderId: order.id,
          orderNumber: order.orderNumber,
          status: newStatus,
          updatedAt: new Date().toISOString(),
        });
    }

    await this._notifyAdminsStatusChange(order, newStatus);
  }

  private async _notifyAdminsStatusChange(order: any, status: OrderStatus) {
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
        await tx.insert(notifications).values({
          id: uuidv4(),
          userId: admin.id,
          type: 'order',
          title: notificationTitle,
          message: notificationMessage,
          actionText: 'View Order',
          actionLink: `/admin/orders/${order.id}`,
        });
      }

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

  // ==========================================
  // EXISTING METHODS (getOrders, getOrderById, etc.)
  // ==========================================

  async getOrders(
    userId: string,
    status?: string,
    page: number = 1,
    limit: number = 10,
  ) {
    const offset = (page - 1) * limit;

    const [user] = await this.drizzle.db
      .select({
        isAdmin: users.isAdmin,
        isSuperAdmin: users.isSuperAdmin,
      })
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    const isAdmin = user?.isAdmin || user?.isSuperAdmin;

    const conditions: any[] = [];

    if (!isAdmin) {
      conditions.push(eq(orders.userId, userId));
    }

    if (status) {
      conditions.push(eq(orders.status, status));
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

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
          user: {
            columns: {
              id: true,
              name: true,
              phoneNumber: true,
              email: true,
            },
          },
        },
      }),
      this.drizzle.db
        .select({ count: sql<number>`COUNT(*)::int` })
        .from(orders)
        .where(whereClause || sql`1=1`),
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
      where: eq(orders.id, orderId),
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
        user: {
          columns: {
            id: true,
            name: true,
            phoneNumber: true,
            email: true,
          },
        },
      },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    const [user] = await this.drizzle.db
      .select({
        isAdmin: users.isAdmin,
        isSuperAdmin: users.isSuperAdmin,
      })
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    const isAdmin = user?.isAdmin || user?.isSuperAdmin;

    if (!isAdmin && order.userId !== userId) {
      throw new ForbiddenException(
        'You do not have permission to view this order',
      );
    }

    return order;
  }

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
    const hasOwnership = await this.validateAddressOwnership(addressId, userId);
    if (!hasOwnership) {
      throw new ForbiddenException(
        'You do not have permission to modify this address',
      );
    }
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
    const hasOwnership = await this.validateAddressOwnership(addressId, userId);
    if (!hasOwnership) {
      throw new ForbiddenException(
        'You do not have permission to delete this address',
      );
    }
    const [deleted] = await this.drizzle.db
      .delete(addresses)
      .where(and(eq(addresses.id, addressId), eq(addresses.userId, userId)))
      .returning();

    if (!deleted) throw new NotFoundException('Address not found');
    return { message: 'Address deleted successfully' };
  }

  private async validateAddressOwnership(
    addressId: string,
    userId: string,
  ): Promise<boolean> {
    const [address] = await this.drizzle.db
      .select({ userId: addresses.userId })
      .from(addresses)
      .where(eq(addresses.id, addressId))
      .limit(1);

    if (!address) {
      throw new NotFoundException('Address not found');
    }

    return address.userId === userId;
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

      const unitPrice = variant?.price
        ? Number(variant.price)
        : Number(product?.price || 0);
      const totalPrice = unitPrice * cartItem.quantity;
      subtotal += totalPrice;

      return {
        id: cartItem.id,
        productVariantId: cartItem.productVariantId,
        productId: product?.id || cartItem.productId,
        name: product?.name || 'Unknown Product',
        price: unitPrice,
        quantity: cartItem.quantity,
        totalPrice,
        inStock: (variant?.stock || product?.stock || 0) > 0,
        imageUrl: product?.images?.[0]?.url || '',
        color: variant?.color?.name || null,
        size: variant?.size?.name || null,
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

    let availableStock = product.stock;
    if (productVariantId) {
      const variant = await this.drizzle.db.query.productVariants.findFirst({
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
      availableStock = variant.stock;
    }

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
      const newQuantity = existingItem.quantity + quantity;
      if (newQuantity > availableStock) {
        throw new BadRequestException(
          `Cannot add more. Maximum stock (${availableStock}) reached. You already have ${existingItem.quantity} in cart.`,
        );
      }

      const [updated] = await this.drizzle.db
        .update(cartItems)
        .set({
          quantity: newQuantity,
          updatedAt: new Date(),
        })
        .where(eq(cartItems.id, existingItem.id))
        .returning();
      return updated;
    }

    if (quantity > availableStock) {
      throw new BadRequestException(
        `Cannot add ${quantity} items. Only ${availableStock} available.`,
      );
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
    const hasOwnership = await this.validateCartItemOwnership(itemId, userId);
    if (!hasOwnership) {
      throw new ForbiddenException('You do not have permission...');
    }
    if (quantity < 1) {
      throw new BadRequestException('Quantity must be at least 1');
    }

    const [existingItem] = await this.drizzle.db
      .select()
      .from(cartItems)
      .where(and(eq(cartItems.id, itemId), eq(cartItems.userId, userId)))
      .limit(1);

    if (!existingItem) throw new NotFoundException('Cart item not found');

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
    const hasOwnership = await this.validateCartItemOwnership(itemId, userId);
    if (!hasOwnership) {
      throw new ForbiddenException(
        'You do not have permission to remove this cart item',
      );
    }
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

  private async validateCartItemOwnership(
    itemId: string,
    userId: string,
  ): Promise<boolean> {
    const [item] = await this.drizzle.db
      .select({ userId: cartItems.userId })
      .from(cartItems)
      .where(eq(cartItems.id, itemId))
      .limit(1);

    if (!item) {
      throw new NotFoundException('Cart item not found');
    }

    return item.userId === userId;
  }
}
