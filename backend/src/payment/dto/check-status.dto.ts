// src/payment/dto/check-status.dto.ts
import { IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CheckPaymentStatusDto {
  @ApiProperty({ description: 'Reference ID from payment initiation' })
  @IsString()
  referenceId: string;
}
