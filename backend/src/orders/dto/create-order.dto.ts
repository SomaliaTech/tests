import {
  IsString,
  IsArray,
  IsUUID,
  IsInt,
  Min,
  IsOptional,
  IsEnum,
  IsBoolean,
  IsPhoneNumber,
  MaxLength,
} from 'class-validator';
import { Type } from 'class-transformer';

export class OrderItemDto {
  @IsUUID()
  productVariantId: string;

  @IsInt()
  @Min(1)
  quantity: number;
}

export class AddressDto {
  @IsString()
  @MaxLength(50)
  label: string;

  @IsString()
  @MaxLength(500)
  fullAddress: string;

  @IsString()
  @IsPhoneNumber()
  phoneNumber: string;

  @IsBoolean()
  @IsOptional()
  isDefault?: boolean;
}

export class CreateOrderDto {
  @IsArray()
  @Type(() => OrderItemDto)
  items: OrderItemDto[];

  @Type(() => AddressDto)
  shippingAddress: AddressDto;

  @IsString()
  @IsOptional()
  @MaxLength(255)
  customerName?: string;

  @IsString()
  @IsOptional()
  customerEmail?: string;

  @IsEnum(['evc_plus', 'cash_on_delivery', 'zaad'])
  paymentMethod: string;

  @IsString()
  @IsOptional()
  notes?: string;
}
