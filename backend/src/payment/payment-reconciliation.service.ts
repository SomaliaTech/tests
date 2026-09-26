// src/payment/payment-reconciliation.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { DrizzleService } from '../drizzle/drizzle.service';
import { OrdersService } from '../orders/orders.service';
import { WaafiPayService } from './waafipay.service';
import { orders } from '../drizzle/schema';
import { and, eq, lt, isNotNull, or } from 'drizzle-orm';
import { OrderStatus, PaymentStatus } from '../orders/enums/order-status.enum';

@Injectable()
export class PaymentReconciliationService {
  private readonly logger = new Logger(PaymentReconciliationService.name);

  constructor(
    private drizzle: DrizzleService,
    private ordersService: OrdersService,
    private waafiPayService: WaafiPayService,
  ) {}

  /**
   * Every 5 minutes, find orders that have been PENDING for more than
   * 10 minutes but have a paymentReferenceId (meaning we initiated payment).
   * Ask WaafiPay what happened.
   */
  @Cron(CronExpression.EVERY_5_MINUTES)
  async reconcilePendingPayments() {
    const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);

    // Find PENDING orders older than 10 min that have a referenceId
    const staleOrders = await this.drizzle.db
      .select({
        id: orders.id,
        orderNumber: orders.orderNumber,
        paymentReferenceId: orders.paymentReferenceId,
        paymentStatus: orders.paymentStatus,
      })
      .from(orders)
      .where(
        and(
          eq(orders.status, OrderStatus.PENDING),
          eq(orders.paymentStatus, PaymentStatus.PENDING),
          isNotNull(orders.paymentReferenceId),
          lt(orders.createdAt, tenMinutesAgo),
        ),
      )
      .limit(50); // batch size

    if (staleOrders.length === 0) return;

    this.logger.log(
      `🔍 Reconciling ${staleOrders.length} stale PENDING orders`,
    );

    for (const order of staleOrders) {
      try {
        const status = await this.waafiPayService.checkPaymentStatus(
          order.paymentReferenceId!,
        );

        if (status.success && status.transactionId) {
          await this.ordersService.updatePaymentStatus(
            order.id,
            PaymentStatus.PAID,
            'admin', // treat cron as admin source
            status.transactionId,
          );
          this.logger.log(`✅ Reconciled order ${order.orderNumber} → PAID`);
        } else if (
          status.responseCode &&
          ['5206', '5310', '5010'].includes(status.responseCode)
        ) {
          // Explicit failure codes
          await this.ordersService.updatePaymentStatus(
            order.id,
            PaymentStatus.FAILED,
            'admin',
          );
          this.logger.warn(
            `❌ Reconciled order ${order.orderNumber} → FAILED (${status.responseCode})`,
          );
        }
        // else: still pending at WaafiPay — leave it alone
      } catch (err) {
        this.logger.error(
          `Reconciliation failed for ${order.orderNumber}: ${err instanceof Error ? err.message : 'unknown'}`,
        );
      }
    }
  }
}
