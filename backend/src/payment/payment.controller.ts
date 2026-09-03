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
  constructor(
    private readonly waafiPayService: WaafiPayService,
    private readonly ordersService: OrdersService,
  ) {}

  @Post('initiate')
  @Throttle({ payment: { limit: 3, ttl: 60000 } })
  @ApiOperation({ summary: 'Initiate WaafiPay payment' })
  @ApiResponse({ status: 200, description: 'Payment initiated' })
  @ApiResponse({ status: 400, description: 'Invalid request' })
  async initiatePayment(@Request() req, @Body() dto: InitiatePaymentDto) {
    // ✅ Verify order exists and belongs to user
    const order = await this.ordersService.getOrderById(
      dto.orderId,
      req.user.userId,
    );

    if (!order) {
      throw new BadRequestException('Order not found');
    }

    // ✅ Validate order state before payment
    if (order.paymentStatus === PaymentStatus.PAID) {
      throw new BadRequestException('Order already paid');
    }

    if (order.paymentStatus === PaymentStatus.REFUNDED) {
      throw new BadRequestException('Order has been refunded');
    }

    if (order.status === 'CANCELLED' || order.status === 'RETURNED') {
      throw new BadRequestException(`Cannot pay for cancelled/returned order`);
    }

    // ✅ Verify amount matches
    const orderAmount = parseFloat(order.totalAmount);
    if (Math.abs(orderAmount - dto.amount) > 0.01) {
      throw new BadRequestException(
        `Amount mismatch. Order amount: ${orderAmount}, provided: ${dto.amount}`,
      );
    }

    const referenceId = this.waafiPayService.generateReferenceId(dto.orderId);

    const result = await this.waafiPayService.initiatePayment({
      amount: dto.amount,
      phoneNumber: dto.phoneNumber,
      orderId: dto.orderId,
      description: dto.description || `Payment for order ${dto.orderId}`,
      referenceId: referenceId,
      paymentMethod: dto.paymentMethod,
    });

    // ✅ If payment successful, update order payment status
    if (result.success) {
      await this.ordersService.updatePaymentStatus(
        dto.orderId,
        PaymentStatus.PAID,
      );
    }

    return {
      ...result,
      referenceId: referenceId,
      orderId: dto.orderId,
    };
  }

  @Get('verify/:referenceId')
  @Throttle({ payment: { limit: 10, ttl: 60000 } })
  @ApiOperation({ summary: 'Verify payment status' })
  @ApiResponse({ status: 200, description: 'Payment status retrieved' })
  async verifyPayment(@Param('referenceId') referenceId: string) {
    const result = await this.waafiPayService.checkPaymentStatus(referenceId);

    // ✅ If payment is confirmed, update order
    if (result.success && result.state === 'SUCCESS') {
      // Extract order ID from reference (format: PAY-ORDERID-TIMESTAMP-RANDOM)
      const parts = referenceId.split('-');
      if (parts.length >= 2) {
        const orderId = parts[1];
        if (orderId) {
          try {
            await this.ordersService.updatePaymentStatus(
              orderId,
              PaymentStatus.PAID,
            );
          } catch (error) {
            // Log but don't fail the verification
            console.warn('Failed to update order payment status:', error);
          }
        }
      }
    }

    return result;
  }
}
