// src/payment/payment-webhook.controller.ts
import {
  Controller,
  Post,
  Body,
  Headers,
  Req,
  HttpCode,
  UnauthorizedException,
  Logger,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, timingSafeEqual } from 'crypto';
import { Request } from 'express';
import { DrizzleService } from '../drizzle/drizzle.service';
import { OrdersService } from '../orders/orders.service';
import { PaymentStatus } from '../orders/enums/order-status.enum';
import { orders } from '../drizzle/schema';
import { eq } from 'drizzle-orm';
import { LogSanitizer } from '../common/utils/log-sanitizer.util';

/**
 * WaafiPay webhook handler.
 *
 * WaafiPay posts a POST request to /payment/webhook/waafipay when a
 * transaction changes state (SUCCESS / FAILED / REVERSED).
 *
 * SECURITY MODEL:
 *  1. Verify HMAC-SHA256 signature via `x-waafipay-signature` header.
 *  2. Idempotency check via `transactionId` — never process twice.
 *  3. Only update order status when the signature is valid AND the
 *     reference matches an order we created.
 *  4. Never trust client-provided success from /payment/initiate —
 *     only this webhook can mark orders as PAID.
 *
 * ENV VARS:
 *   WAAFI_WEBHOOK_SECRET — shared secret configured in WaafiPay dashboard
 *   WAAFI_WEBHOOK_IPS    — optional comma-separated IP allowlist
 */
@Controller('payment/webhook')
export class PaymentWebhookController {
  private readonly logger = new Logger(PaymentWebhookController.name);
  private readonly webhookSecret: string;
  private readonly allowedIps: string[];

  constructor(
    private config: ConfigService,
    private drizzle: DrizzleService,
    private ordersService: OrdersService,
  ) {
    this.webhookSecret = this.config.get<string>('WAAFI_WEBHOOK_SECRET') || '';
    if (!this.webhookSecret) {
      this.logger.error(
        '❌ WAAFI_WEBHOOK_SECRET is not configured — webhooks will be rejected',
      );
    } else {
      this.logger.log('✅ WaafiPay webhook secret configured');
    }

    const ips = this.config.get<string>('WAAFI_WEBHOOK_IPS') || '';
    this.allowedIps = ips
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);

    if (this.allowedIps.length > 0) {
      this.logger.log(
        `✅ WaafiPay webhook IP allowlist: ${this.allowedIps.length} entries`,
      );
    }
  }

  // ==========================================
  // ✅ MAIN WEBHOOK HANDLER
  // ==========================================
  @Post('waafipay')
  @HttpCode(200)
  async handleWaafiPayWebhook(
    @Req() req: Request & { rawBody?: Buffer },
    @Headers('x-waafipay-signature') signature: string,
    @Headers('x-waafipay-timestamp') timestamp: string | undefined,
    @Body() body: any,
  ) {
    const startTime = Date.now();
    this.logger.log('🔔 WaafiPay webhook received');

    // ✅ Log IP once (used by allowlist check below)
    const clientIp =
      (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() ||
      req.socket?.remoteAddress ||
      req.ip ||
      'unknown';

    this.logger.log(`🔔 WaafiPay webhook from IP: ${clientIp}`);

    // ==========================================
    // ✅ LAYER 1: IP ALLOWLIST (optional)
    // ==========================================
    if (this.allowedIps.length > 0) {
      const isAllowed = this.allowedIps.some(
        (allowed) => clientIp === allowed || clientIp.startsWith(allowed),
      );

      if (!isAllowed) {
        this.logger.warn(`❌ Webhook rejected — IP not allowed: ${clientIp}`);
        throw new ForbiddenException('IP not allowed');
      }
    }
    // ==========================================
    // ✅ LAYER 2: SIGNATURE VERIFICATION
    // ==========================================
    if (!this.webhookSecret) {
      this.logger.error('❌ Webhook secret not configured');
      throw new UnauthorizedException('Webhook not configured');
    }

    if (!signature) {
      this.logger.warn('❌ Missing x-waafipay-signature header');
      throw new UnauthorizedException('Missing signature');
    }

    // ⚠️ MUST use RAW body — parsed JSON will produce a different hash
    const rawBody =
      req.rawBody?.toString('utf8') ??
      (typeof req.body === 'string' ? req.body : JSON.stringify(body));

    // Optionally bind signature to timestamp to prevent replay (recommended)
    const signedPayload = timestamp ? `${timestamp}.${rawBody}` : rawBody;

    const expectedSignature = createHmac('sha256', this.webhookSecret)
      .update(signedPayload)
      .digest('hex');

    let isValidSignature = false;
    try {
      const sigBuf = Buffer.from(signature, 'hex');
      const expBuf = Buffer.from(expectedSignature, 'hex');
      if (sigBuf.length === expBuf.length) {
        isValidSignature = timingSafeEqual(sigBuf, expBuf);
      }
    } catch {
      isValidSignature = false;
    }

    if (!isValidSignature) {
      this.logger.error('❌ Invalid WaafiPay webhook signature');
      throw new UnauthorizedException('Invalid signature');
    }

    this.logger.log('✅ Signature verified');

    // ==========================================
    // ✅ LAYER 3: PARSE PAYLOAD
    // ==========================================
    const params = body?.serviceParams || body?.params || body || {};

    const referenceId: string | undefined =
      params.referenceId || body.referenceId;
    const transactionId: string | undefined =
      params.transactionId || body.transactionId;
    const responseCode: string = params.responseCode || body.responseCode || '';
    const responseMsg: string = params.responseMsg || body.responseMsg || '';
    const state: string = params.state || body.state || '';

    // WaafiPay echoes invoiceId which we set = order UUID
    const invoiceId: string | undefined =
      params.invoiceId || body.invoiceId || params.transactionInfo?.invoiceId;

    this.logger.log(
      `📦 Payload: ref=${LogSanitizer.maskValue(referenceId)} ` +
        `txn=${LogSanitizer.maskValue(transactionId)} ` +
        `code=${responseCode} state=${state} ` +
        `invoice=${LogSanitizer.maskValue(invoiceId)}`,
    );

    if (!referenceId) {
      this.logger.warn('❌ Missing referenceId — cannot match to order');
      throw new BadRequestException('Missing referenceId');
    }

    // ==========================================
    // ✅ LAYER 4: IDEMPOTENCY CHECK
    // ==========================================
    if (transactionId) {
      const [existing] = await this.drizzle.db
        .select({
          id: orders.id,
          paymentStatus: orders.paymentStatus,
        })
        .from(orders)
        .where(eq(orders.paymentReferenceId, transactionId))
        .limit(1);

      if (existing) {
        this.logger.log(
          `♻️ Duplicate webhook for txn ${LogSanitizer.maskValue(transactionId)} — ignoring`,
        );
        return {
          received: true,
          duplicate: true,
          orderId: existing.id,
        };
      }
    }

    // ==========================================
    // ✅ LAYER 5: RESOLVE ORDER
    // ==========================================
    // Primary: invoiceId (order UUID we set during initiate)
    // Fallback: referenceId starts with "PAY-XXXXXXXX-..." where XXXXXXXX is first 8 chars
    let orderId: string | null = null;

    if (invoiceId && this.isUuid(invoiceId)) {
      orderId = invoiceId;
    } else if (referenceId) {
      // referenceId format: PAY-XXXXXXXX-TIMESTAMP-RANDOM
      const parts = referenceId.split('-');
      if (parts.length >= 2 && parts[0] === 'PAY' && parts[1].length === 8) {
        // We only have first 8 chars of UUID — need DB search
        const matches = await this.drizzle.db
          .select({ id: orders.id })
          .from(orders)
          .where(eq(orders.paymentReferenceId, referenceId))
          .limit(1);

        if (matches.length > 0) {
          orderId = matches[0].id;
        }
      }
    }

    if (!orderId) {
      this.logger.error(
        `❌ Cannot match webhook to order — invoice=${invoiceId} ref=${referenceId}`,
      );
      // Return 200 so WaafiPay doesn't retry endlessly
      return { received: true, matched: false };
    }

    // ==========================================
    // ✅ LAYER 6: DETERMINE SUCCESS / FAILURE
    // ==========================================
    const isSuccess =
      responseCode === '2001' ||
      state === 'SUCCESS' ||
      state === 'APPROVED' ||
      responseMsg.toLowerCase().includes('success');

    const isFailure =
      responseCode === '5310' || // rejected/cancelled
      responseCode === '5005' || // insufficient funds
      state === 'FAILED' ||
      state === 'REJECTED' ||
      state === 'CANCELLED';

    // ==========================================
    // ✅ LAYER 7: APPLY TO ORDER
    // ==========================================
    try {
      if (isSuccess) {
        await this.ordersService.updatePaymentStatus(
          orderId,
          PaymentStatus.PAID,
          'webhook',
          transactionId,
        );
        this.logger.log(
          `✅ Order ${orderId} marked PAID (txn=${transactionId})`,
        );
      } else if (isFailure) {
        await this.ordersService.updatePaymentStatus(
          orderId,
          PaymentStatus.FAILED,
          'webhook',
          transactionId,
        );
        this.logger.warn(
          `❌ Order ${orderId} payment FAILED (code=${responseCode}, msg=${responseMsg})`,
        );
      } else {
        // Pending / informational — leave as PENDING
        this.logger.log(
          `⏳ Order ${orderId} payment still PENDING (state=${state})`,
        );
      }
    } catch (err) {
      this.logger.error(
        `Failed to apply webhook to order ${orderId}: ${err instanceof Error ? err.message : 'unknown'}`,
      );
      // Throw so WaafiPay retries
      throw err;
    }

    this.logger.log(`✅ Webhook processed in ${Date.now() - startTime}ms`);

    return {
      received: true,
      orderId,
      status: isSuccess ? 'PAID' : isFailure ? 'FAILED' : 'PENDING',
    };
  }

  // ==========================================
  // ✅ HELPER: UUID CHECK
  // ==========================================
  private isUuid(s: string): boolean {
    return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
      s,
    );
  }
}
