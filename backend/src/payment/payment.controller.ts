// src/payment/payment.controller.ts
import {
  Controller,
  Post,
  Body,
  UseGuards,
  Request,
  Param,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { WaafiPayService } from './waafipay.service';
import { InitiatePaymentDto } from './dto/initiate-payment.dto';

@ApiTags('payment')
@Controller('payment')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
export class PaymentController {
  constructor(
    private readonly waafiPayService: WaafiPayService,
    // ❌ REMOVE OrdersService - no longer needed
  ) {}

  @Post('initiate')
  @ApiOperation({ summary: 'Initiate WaafiPay payment' })
  @ApiResponse({ status: 200, description: 'Payment initiated' })
  @ApiResponse({ status: 400, description: 'Invalid request' })
  async initiatePayment(@Request() req, @Body() dto: InitiatePaymentDto) {
    const referenceId = this.waafiPayService.generateReferenceId(dto.orderId);

    const result = await this.waafiPayService.initiatePayment({
      amount: dto.amount,
      phoneNumber: dto.phoneNumber,
      orderId: dto.orderId,
      description: dto.description || `Payment for order ${dto.orderId}`,
      referenceId: referenceId,
    });

    // ❌ REMOVE: No need to call processPayment on OrdersService
    // Payment is now handled inside createOrder

    return {
      ...result,
      referenceId: referenceId,
    };
  }

  @Post('verify/:referenceId')
  @ApiOperation({ summary: 'Verify payment status' })
  @ApiResponse({ status: 200, description: 'Payment status retrieved' })
  async verifyPayment(@Param('referenceId') referenceId: string) {
    return this.waafiPayService.checkPaymentStatus(referenceId);
  }
}
