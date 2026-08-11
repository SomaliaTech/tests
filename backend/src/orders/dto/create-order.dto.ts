// src/orders/dto/create-order.dto.ts
import {
  IsString,
  IsArray,
  IsOptional,
  IsNumber,
  ValidateNested,
  IsNotEmpty,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

class OrderItemDto {
  @ApiProperty({ description: 'Product ID' })
  @IsString()
  @IsNotEmpty()
  productId: string;

  @ApiProperty({ description: 'Product variant ID', required: false })
  @IsOptional()
  @IsString()
  productVariantId?: string;

  @ApiProperty({ description: 'Quantity' })
  @IsNumber()
  @Min(1)
  quantity: number;
}

class ShippingAddressDto {
  @ApiProperty({ description: 'Address label', example: 'Home' })
  @IsString()
  @IsNotEmpty()
  label: string;

  @ApiProperty({ description: 'Full address' })
  @IsString()
  @IsNotEmpty()
  fullAddress: string;

  @ApiProperty({ description: 'Phone number' })
  @IsString()
  @IsNotEmpty()
  phoneNumber: string;
}

export class CreateOrderDto {
  @ApiProperty({ description: 'Order items', type: [OrderItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items: OrderItemDto[];

  @ApiProperty({ description: 'Shipping address', type: ShippingAddressDto })
  @ValidateNested()
  @Type(() => ShippingAddressDto)
  shippingAddress: ShippingAddressDto; // ✅ Now allowed

  @ApiProperty({ description: 'Payment method', example: 'evc_plus' })
  @IsString()
  @IsNotEmpty()
  paymentMethod: string;

  @ApiProperty({ description: 'Phone number for payment', required: false })
  @IsOptional()
  @IsString()
  phoneNumber?: string; // ✅ Now allowed

  @ApiProperty({ description: 'Delivery fee', required: false })
  @IsOptional()
  @IsNumber()
  deliveryFee?: number; // ✅ Now allowed

  @ApiProperty({ description: 'Order notes', required: false })
  @IsOptional()
  @IsString()
  notes?: string;
}
