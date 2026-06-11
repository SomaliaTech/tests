import { IsString, IsOptional } from 'class-validator';

export class ProcessPaymentDto {
  @IsString()
  paymentMethod: string;

  @IsString()
  @IsOptional()
  phoneNumber?: string;
}
