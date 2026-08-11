// src/payment/dto/initiate-payment.dto.ts
import { IsString, IsNumber, IsOptional, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class InitiatePaymentDto {
  @ApiProperty({ description: 'Order ID', example: 'uuid' })
  @IsString()
  orderId: string;

  @ApiProperty({
    description: 'Phone number for payment',
    example: '612345678',
  })
  @IsString()
  phoneNumber: string;

  @ApiProperty({ description: 'Payment amount', example: 50.0 })
  @IsNumber()
  @Min(0.01)
  amount: number;

  @ApiProperty({
    description: 'Payment description',
    example: 'Order #ORD-123',
  })
  @IsOptional()
  @IsString()
  description?: string;
}
