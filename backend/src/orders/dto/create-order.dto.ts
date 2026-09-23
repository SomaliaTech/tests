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
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

class OrderItemDto {
  @ApiProperty({ description: 'Product ID' })
  @IsString()
  @IsNotEmpty()
  productId!: string; // ✅ Added !

  @ApiProperty({ description: 'Product variant ID', required: false })
  @IsOptional()
  @IsString()
  productVariantId?: string;

  @ApiProperty({ description: 'Quantity' })
  @IsNumber()
  @Min(1)
  quantity!: number; // ✅ Added !
}

class ShippingAddressDto {
  @ApiProperty({ description: 'Address label', example: 'Home' })
  @IsString()
  @IsNotEmpty()
  label!: string; // ✅ Added !

  @ApiProperty({ description: 'Full address' })
  @IsString()
  @IsNotEmpty()
  fullAddress!: string; // ✅ Added !

  @ApiProperty({ description: 'Phone number' })
  @IsString()
  @IsNotEmpty()
  phoneNumber!: string; // ✅ Added !
}

export class CreateOrderDto {
  @ApiProperty({ description: 'Order items', type: [OrderItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items!: OrderItemDto[]; // ✅ Added !

  @ApiProperty({ description: 'Shipping address', type: ShippingAddressDto })
  @ValidateNested()
  @Type(() => ShippingAddressDto)
  shippingAddress!: ShippingAddressDto; // ✅ Added !

  @ApiProperty({ description: 'Payment method', example: 'evc_plus' })
  @IsString()
  @IsNotEmpty()
  paymentMethod!: string; // ✅ Added !

  @ApiProperty({ description: 'Phone number for payment', required: false })
  @IsOptional()
  @IsString()
  phoneNumber?: string;

  @ApiProperty({ description: 'Delivery fee', required: false })
  @IsOptional()
  @IsNumber()
  deliveryFee?: number;

  @ApiProperty({ description: 'Order notes', required: false })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({
    description: 'Promo code to apply',
    example: 'SAVE20',
  })
  @IsOptional()
  @IsString()
  promoCode?: string;
}
