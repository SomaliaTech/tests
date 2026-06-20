import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional } from 'class-validator';

export class ProcessPaymentDto {
  @ApiProperty({
    description: 'Payment method',
    example: 'cash',
    enum: ['cash', 'card', 'mobile_money'],
  })
  @IsString()
  paymentMethod: string;

  @ApiProperty({
    description: 'Phone number for mobile money payments',
    example: '+252612345678',
    required: false,
  })
  @IsString()
  @IsOptional()
  phoneNumber?: string;
}
