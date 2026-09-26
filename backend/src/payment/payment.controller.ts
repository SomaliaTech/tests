// src/payment/payment.controller.ts
import {
  Controller,
  Post,
  Body,
  UseGuards,
  Request,
  Param,
  BadRequestException,
  Get,
  Logger,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { WaafiPayService } from './waafipay.service';
import { InitiatePaymentDto } from './dto/initiate-payment.dto';
import { OrdersService } from '../orders/orders.service';
import { PaymentStatus } from '../orders/enums/order-status.enum';

@ApiTags('payment')
@Controller('payment')
@UseGuards(JwtAuthGuard, ThrottlerGuard)
@ApiBearerAuth('JWT-auth')
export class PaymentController {
  private readonly logger = new Logger(PaymentController.name);
  constructor(
    private readonly waafiPayService: WaafiPayService,
    private readonly ordersService: OrdersService,
  ) {}

  // ==========================================
  // ✅ INITIATE PAYMENT
  // ==========================================
  // ⚠️ CRITICAL: This endpoint only INITIATES the payment.
  // It does NOT mark the order as PAID. Only the webhook does that.
  // ==========================================
  @Post('initiate')
  @Throttle({ payment: { limit: 3, ttl: 60000 } })
  @ApiOperation({ summary: 'Initiate WaafiPay payment' })
  @ApiResponse({ status: 200, description: 'Payment initiated' })
  @ApiResponse({ status: 400, description: 'Invalid request' })
  async initiatePayment(@Request() req, @Body() dto: InitiatePaymentDto) {
    // ✅ Verify order exists and belongs to the requesting user
    const order = await this.ordersService.getOrderById(
      dto.orderId,
      req.user.userId,
    );

    if (!order) {
      throw new BadRequestException('Order not found');
    }

    // ✅ Guard: already paid?
    if (order.paymentStatus === PaymentStatus.PAID) {
      throw new BadRequestException('Order already paid');
    }

    if (order.paymentStatus === PaymentStatus.REFUNDED) {
      throw new BadRequestException('Order has been refunded');
    }

    if (order.status === 'CANCELLED' || order.status === 'RETURNED') {
      throw new BadRequestException(
        'Cannot pay for cancelled or returned order',
      );
    }

    // ✅ Guard: amount must match order total exactly
    const orderAmount = parseFloat(order.totalAmount);
    if (Math.abs(orderAmount - dto.amount) > 0.01) {
      throw new BadRequestException(
        `Amount mismatch. Order total: ${orderAmount}, provided: ${dto.amount}`,
      );
    }

    // ✅ Generate unique referenceId (idempotency for our own API)
    const referenceId = this.waafiPayService.generateReferenceId(order.id);

    // ✅ Initiate payment with WaafiPay — pass the full order UUID as orderId
    const result = await this.waafiPayService.initiatePayment({
      amount: dto.amount,
      phoneNumber: dto.phoneNumber,
      orderId: order.id, // ✅ full UUID, will become invoiceId
      description: dto.description || `Payment for order ${order.orderNumber}`,
      referenceId,
      paymentMethod: dto.paymentMethod,
    });

    // ⚠️ DO NOT update order status here.
    // The WaafiPay async webhook is the single source of truth.
    // We only log the sync response for diagnostics.

    this.logger?.log?.(
      `Initiate response: success=${result.success} state=${result.state}`,
    );

    return {
      success: result.success, // informational only
      message: result.success
        ? 'Payment request sent. You will receive a prompt on your phone. Please approve to complete payment.'
        : result.message,
      referenceId,
      orderId: order.id,
      // ⚠️ Do NOT return transactionId from sync response
      // — the client should poll /payment/status/:orderId instead
    };
  }

  // ==========================================
  // ✅ VERIFY PAYMENT (client-side polling)
  // ==========================================
  // ⚠️ Read-only. Does NOT update DB. Webhook is the only writer.
  // ==========================================
  @Get('verify/:referenceId')
  @Throttle({ payment: { limit: 10, ttl: 60000 } })
  @ApiOperation({ summary: 'Check payment status (read-only)' })
  @ApiResponse({ status: 200, description: 'Payment status retrieved' })
  async verifyPayment(
    @Request() req,
    @Param('referenceId') referenceId: string,
  ) {
    const result = await this.waafiPayService.checkPaymentStatus(referenceId);

    // ✅ Read-only: return to client so they know whether to wait longer
    // NEVER update order status here. The webhook is authoritative.
    return {
      success: result.success,
      state: result.state,
      message: result.message,
      referenceId,
    };
  }

  // ==========================================
  // ✅ POLL ORDER STATUS (for Flutter client)
  // ==========================================
  @Get('status/:orderId')
  @Throttle({ payment: { limit: 30, ttl: 60000 } })
  @ApiOperation({ summary: 'Poll order payment status' })
  async getOrderPaymentStatus(
    @Request() req,
    @Param('orderId') orderId: string,
  ) {
    const order = await this.ordersService.getOrderById(
      orderId,
      req.user.userId,
    );

    return {
      orderId: order.id,
      orderNumber: order.orderNumber,
      paymentStatus: order.paymentStatus,
      status: order.status,
      totalAmount: order.totalAmount,
    };
  }
}
