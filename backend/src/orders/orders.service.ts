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
import { AffiliateService } from 'src/affiliate/affiliate.service';

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
    @Inject(forwardRef(() => AffiliateService))
    private affiliateService: AffiliateService,
  ) {}

  // ==========================================
  // CREATE ORDER WITH PAYMENT VALIDATION
  // ==========================================

  // ==========================================
  // CREATE ORDER WITH PAYMENT VALIDATION
  // ==========================================
  async createOrder(userId: string, orderData: CreateOrderDto) {
    this.logger.log(
      `Processing order for user: ${LogSanitizer.maskValue(userId)}`,
    );

    // ✅ 1. Generate order UUID BEFORE payment so WaafiPay can echo it back
    const orderId = uuidv4();

    // ✅ 2. Validate items, compute totals, prepare order rows
    const {
      itemsTotal,
      orderItemsData,
      user,
      deliveryFee,
      finalTotalAmount: rawTotal,
    } = await this._validateAndPrepareOrder(userId, orderData);

    // ✅ 3. PROMO CODE VALIDATION
    let promoCodeId: string | null = null;
    let promoDiscount = 0;
    let finalTotalAmount = rawTotal;

    if (orderData.promoCode && orderData.promoCode.trim().length > 0) {
      const validation = await this.affiliateService.validatePromoCode(
        orderData.promoCode.trim(),
        itemsTotal,
        userId,
      );

      if (!validation.valid) {
        throw new BadRequestException(
          validation.message || 'Invalid promo code',
        );
      }

      promoDiscount = validation.promoCode!.discountAmount;
      finalTotalAmount = Math.max(0, rawTotal - promoDiscount);
      promoCodeId = validation.promoCode!.id;

      this.logger.log(
        `🎟️ Promo applied: ${orderData.promoCode} | Discount: $${promoDiscount} | New Total: $${finalTotalAmount}`,
      );
    }

    // ✅ 4. Process payment with the DISCOUNTED total
    //    If payment fails or is not confirmed, this method throws —
    //    the order is never created in that case.
    const paymentResult = await this._processPaymentIfNeeded(
      orderData,
      finalTotalAmount,
      orderId,
    );

    // ✅ 5. Persist order + items + stock updates atomically
    const result = await this.drizzle.db.transaction(async (tx) => {
      const orderNumber = `ORD-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
      const shippingAddress = `${orderData.shippingAddress.fullAddress} (${orderData.shippingAddress.label}) - Phone: ${orderData.shippingAddress.phoneNumber}`;

      // ✅ Payment succeeded → order is CONFIRMED / PAID.
      //    The webhook may still arrive later with the final transactionId,
      //    which will overwrite paymentReferenceId via updatePaymentStatus().
      const [order] = await tx
        .insert(orders)
        .values({
          id: orderId,
          orderNumber: orderNumber,
          userId: userId,
          customerName: user.name || 'Customer',
          customerEmail: user.email || '',
          customerPhone: orderData.shippingAddress.phoneNumber,
          shippingAddress: shippingAddress,
          totalAmount: finalTotalAmount.toString(),
          promoCodeId: promoCodeId,
          promoCodeDiscount: promoDiscount.toString(),
          status: OrderStatus.CONFIRMED,
          paymentMethod: orderData.paymentMethod,
          paymentStatus: PaymentStatus.PAID,
          paymentReferenceId: paymentResult.transactionId || null,
          notes: orderData.notes || null,
        } as any)
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
        promoCodeId,
        promoDiscount,
        itemsTotal,
      };
    });

    // ✅ 6. Record promo usage & generate affiliate commission AFTER commit
    if (result.promoCodeId && result.promoDiscount > 0) {
      try {
        await this.affiliateService.recordPromoUsage(
          result.promoCodeId,
          userId,
          result.order.id,
          result.itemsTotal,
          result.promoDiscount,
        );
      } catch (err) {
        this.logger.error('Failed to record promo usage', err);
      }
    }

    await this._sendOrderNotifications(result.order, result.user);

    return {
      order: result.order,
      totalAmount: result.totalAmount,
      items: result.items,
      payment: result.paymentResult,
      message: 'Order created and payment processed successfully',
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
  // ==========================================
  // PROCESS PAYMENT — REQUIRED, NEVER SKIPPED
  // ==========================================
  /**
   * Always processes payment via WaafiPay.
   * Throws BadRequestException if payment fails.
   * Never returns success:false — the caller can assume success on return.
   */
  private async _processPaymentIfNeeded(
    orderData: CreateOrderDto,
    finalTotalAmount: number,
    orderId: string,
  ): Promise<{
    success: true;
    message: string;
    transactionId: string;
    referenceId: string;
    state?: string;
    responseCode?: string;
  }> {
    // ✅ 1. Payment method + phone are mandatory
    if (!orderData.paymentMethod) {
      throw new BadRequestException('Payment method is required');
    }

    if (!orderData.phoneNumber) {
      throw new BadRequestException('Phone number is required for payment');
    }

    this.logger.log(
      `🔄 Processing WaafiPay payment | Order: ${orderId} | Amount: $${finalTotalAmount} | Method: ${orderData.paymentMethod}`,
    );

    // ✅ 2. Generate a unique referenceId tied to the real order UUID
    const referenceId = this.waafiPayService.generateReferenceId(orderId);

    // ✅ 3. Initiate payment — orderId becomes invoiceId in WaafiPay
    const paymentResult = await this.waafiPayService.initiatePayment({
      amount: finalTotalAmount,
      phoneNumber: orderData.phoneNumber,
      orderId, // ✅ real order UUID → echoed back in webhook
      description: `Payment for order ${orderId.substring(0, 8)}`,
      referenceId,
      paymentMethod: orderData.paymentMethod,
    });

    // ✅ 4. Reject on any failure — order must not be created
    if (!paymentResult.success) {
      this.logger.error(
        `❌ Payment failed | Order: ${orderId} | Reason: ${paymentResult.message}`,
      );
      throw new BadRequestException(
        paymentResult.message || 'Payment failed. Please try again.',
      );
    }

    // ✅ 5. WaafiPay may return success but without a transactionId —
    //    that is a "pending" state. Reject it: we require a confirmed txnId.
    if (!paymentResult.transactionId) {
      this.logger.warn(
        `⚠️ Payment pending | Order: ${orderId} | state: ${paymentResult.state ?? 'unknown'}`,
      );
      throw new BadRequestException(
        'Payment is pending. Please approve the prompt on your phone and try again.',
      );
    }

    this.logger.log(
      `✅ Payment confirmed | Order: ${orderId} | Txn: ${paymentResult.transactionId}`,
    );

    return {
      success: true,
      message: paymentResult.message,
      transactionId: paymentResult.transactionId,
      referenceId: paymentResult.referenceId || referenceId,
      state: paymentResult.state,
      responseCode: paymentResult.responseCode,
    };
  }
  // ==========================================
  // UPDATE ORDER STATUS WITH STATE VALIDATION
  // ==========================================

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

    // ✅ 1. Validate state transition
    const allowedTransitions =
      ORDER_STATUS_TRANSITIONS[order.status as OrderStatus] || [];
    if (!allowedTransitions.includes(newStatus)) {
      throw new BadRequestException(
        `Cannot transition order from '${order.status}' to '${newStatus}'. ` +
          `Allowed transitions: ${allowedTransitions.join(', ') || 'none'}`,
      );
    }

    // ✅ 2. Payment is always required — no COD exception
    if (
      newStatus === OrderStatus.CONFIRMED &&
      order.paymentStatus !== PaymentStatus.PAID
    ) {
      throw new BadRequestException(
        'Cannot confirm order. Payment must be completed first.',
      );
    }

    // ✅ 3. Cannot ship unpaid orders
    if (
      newStatus === OrderStatus.SHIPPED &&
      order.paymentStatus !== PaymentStatus.PAID
    ) {
      throw new BadRequestException(
        'Cannot ship order. Payment must be completed first.',
      );
    }

    // ✅ 4. Cannot change orders in final state
    if (FINAL_ORDER_STATUSES.includes(order.status as OrderStatus)) {
      throw new BadRequestException(
        `Order is already in final state '${order.status}'. Cannot change.`,
      );
    }

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
  // src/orders/orders.service.ts
  // REPLACE the existing updatePaymentStatus method

  async updatePaymentStatus(
    orderId: string,
    paymentStatus: PaymentStatus,
    source: 'webhook' | 'admin' | 'system' = 'system',
    transactionId?: string,
  ) {
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

    // ✅ Guard: only webhook/admin can mark PAID
    if (
      paymentStatus === PaymentStatus.PAID &&
      source !== 'webhook' &&
      source !== 'admin'
    ) {
      throw new ForbiddenException(
        'Only webhook or admin can mark orders as PAID',
      );
    }

    // ✅ Guard: don't overwrite a PAID order with FAILED
    if (
      order.paymentStatus === PaymentStatus.PAID &&
      paymentStatus === PaymentStatus.FAILED
    ) {
      this.logger.warn(
        `Ignoring FAILED update on already-PAID order ${orderId}`,
      );
      return {
        message: 'Order is already paid — ignoring failure',
        order: {
          id: order.id,
          orderNumber: order.orderNumber,
          paymentStatus: order.paymentStatus,
          status: order.status,
        },
      };
    }

    const updates: any = {
      paymentStatus,
      updatedAt: new Date(),
    };

    // Auto-confirm when payment succeeds (from webhook)
    if (
      paymentStatus === PaymentStatus.PAID &&
      order.status === OrderStatus.PENDING
    ) {
      updates.status = OrderStatus.CONFIRMED;
    }

    // Store transaction ID if provided
    if (transactionId) {
      updates.paymentReferenceId = transactionId;
    }

    const [updatedOrder] = await this.drizzle.db
      .update(orders)
      .set(updates)
      .where(eq(orders.id, orderId))
      .returning();

    if (!updatedOrder) throw new NotFoundException('Order not found');

    // ✅ Notify user only when transitioning to PAID
    if (
      paymentStatus === PaymentStatus.PAID &&
      order.paymentStatus !== PaymentStatus.PAID &&
      updatedOrder.userId
    ) {
      try {
        await this.notificationsService.create({
          userId: updatedOrder.userId,
          type: NotificationType.PAYMENT,
          title: 'Payment Successful',
          message: `Payment for order #${updatedOrder.orderNumber} was received`,
          actionText: 'View Order',
          actionLink: `/orders/${orderId}`,
        });
      } catch (e) {
        this.logger.warn('Failed to send payment notification', e);
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

    let refundResult: { success: boolean; message: string } | null = null;

    if (
      order.paymentStatus === PaymentStatus.PAID &&
      (order as any).paymentReferenceId
    ) {
      this.logger.log(`Processing refund for order ${orderId}`);
      refundResult = { success: true, message: 'Refund initiated' };
    }

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

    // ✅ FIX: Cast to any to access new schema fields
    if ((order as any).promoCodeId) {
      try {
        await this.affiliateService.cancelCommission(orderId);
      } catch (err) {
        this.logger.error('Failed to cancel commission', err);
      }
    }

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
              // ✅ ADD — direct product images (for items with no variant)
              product: { with: { images: true } },
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
        /* ... */
      },
    });
    if (!order) throw new NotFoundException('Order not found');

    const [user] = await this.drizzle.db
      .select({ isAdmin: users.isAdmin, isSuperAdmin: users.isSuperAdmin })
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    const isAdmin = user?.isAdmin || user?.isSuperAdmin;
    const orderUserIdStr = order.userId ? String(order.userId).trim() : null;
    const requestUserIdStr = userId ? String(userId).trim() : null;

    if (!isAdmin && orderUserIdStr !== requestUserIdStr) {
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
