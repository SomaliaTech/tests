import { IsString, IsEnum } from 'class-validator';

export class UpdateOrderStatusDto {
  @IsString()
  @IsEnum(['PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED'])
  status: string;
}
