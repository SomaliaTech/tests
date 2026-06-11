import {
  IsString,
  IsArray,
  ValidateNested,
  IsOptional,
  IsNotEmpty,
  IsNumber,
  IsBoolean,
} from 'class-validator';
import { Type } from 'class-transformer';

// 1. Define the structure for Order Items
export class OrderItemDto {
  @IsString()
  @IsNotEmpty()
  productVariantId: string;

  @IsNumber()
  quantity: number;
}

// 2. Define the structure for the Address
// (If you already have an AddressDto in another file, you can import it instead)
export class AddressDto {
  @IsString()
  @IsNotEmpty()
  label: string;

  @IsString()
  @IsNotEmpty()
  fullAddress: string;

  @IsString()
  @IsNotEmpty()
  phoneNumber: string;

  // 🚨 ADDED THIS:
  @IsBoolean()
  @IsOptional()
  isDefault?: boolean;
}

// 3. The Main CreateOrderDto
export class CreateOrderDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items: OrderItemDto[];

  // 🚨 THIS WAS MISSING! Add this to accept the shipping address object
  @ValidateNested()
  @Type(() => AddressDto)
  shippingAddress: AddressDto;

  @IsString()
  @IsNotEmpty()
  paymentMethod: string;

  @IsString()
  @IsOptional()
  notes?: string;
}
