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
import { ApiProperty } from '@nestjs/swagger';

export class OrderItemDto {
  @ApiProperty({
    description: 'Product variant UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsString()
  @IsNotEmpty()
  productVariantId: string;

  @ApiProperty({
    description: 'Quantity of the product',
    example: 2,
    minimum: 1,
  })
  @IsNumber()
  quantity: number;
}

export class AddressDto {
  @ApiProperty({
    description: 'Address label',
    example: 'Home',
  })
  @IsString()
  @IsNotEmpty()
  label: string;

  @ApiProperty({
    description: 'Full street address',
    example: '123 Main Street, Mogadishu, Somalia',
  })
  @IsString()
  @IsNotEmpty()
  fullAddress: string;

  @ApiProperty({
    description: 'Phone number in international format',
    example: '+252612345678',
  })
  @IsString()
  @IsNotEmpty()
  phoneNumber: string;

  @ApiProperty({
    description: 'Set as default address',
    example: true,
    required: false,
  })
  @IsBoolean()
  @IsOptional()
  isDefault?: boolean;
}

export class CreateOrderDto {
  @ApiProperty({
    description: 'Array of order items',
    type: [OrderItemDto],
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items: OrderItemDto[];

  @ApiProperty({
    description: 'Shipping address for the order',
    type: AddressDto,
  })
  @ValidateNested()
  @Type(() => AddressDto)
  shippingAddress: AddressDto;

  @ApiProperty({
    description: 'Payment method (e.g., cash, card, mobile money)',
    example: 'cash',
  })
  @IsString()
  @IsNotEmpty()
  paymentMethod: string;

  @ApiProperty({
    description: 'Order notes or special instructions',
    example: 'Please deliver after 5 PM',
    required: false,
  })
  @IsString()
  @IsOptional()
  notes?: string;
}
