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
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { WaafiPayService } from './waafipay.service';
import { InitiatePaymentDto } from './dto/initiate-payment.dto';

@ApiTags('payment')
@Controller('payment')
@UseGuards(JwtAuthGuard, ThrottlerGuard)
@ApiBearerAuth('JWT-auth')
export class PaymentController {
  constructor(private readonly waafiPayService: WaafiPayService) {}

  @Post('initiate')
  @Throttle({ payment: { limit: 3, ttl: 60000 } }) // Extremely strict
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

    return {
      ...result,
      referenceId: referenceId,
    };
  }

  @Post('verify/:referenceId')
  @Throttle({ payment: { limit: 10, ttl: 60000 } })
  @ApiOperation({ summary: 'Verify payment status' })
  @ApiResponse({ status: 200, description: 'Payment status retrieved' })
  async verifyPayment(@Param('referenceId') referenceId: string) {
    return this.waafiPayService.checkPaymentStatus(referenceId);
  }
}
