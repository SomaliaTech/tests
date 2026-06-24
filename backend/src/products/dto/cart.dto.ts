import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsInt,
  Min,
  IsUUID,
  IsNotEmpty,
  IsOptional,
} from 'class-validator';

export class AddToCartDto {
  @ApiPropertyOptional({ description: 'Product variant ID (Optional)' })
  @IsUUID()
  @IsOptional()
  productVariantId?: string;

  @ApiProperty({ description: 'Product ID (Required)' })
  @IsUUID()
  @IsNotEmpty()
  productId: string;

  @ApiProperty({ description: 'Quantity to add', minimum: 1 })
  @IsInt()
  @Min(1)
  quantity: number;
}

// Alias for backward compatibility
export { AddToCartDto as AddProductToCartDto };

export class UpdateCartItemDto {
  @ApiProperty({
    description: 'New quantity',
    example: 2,
    minimum: 1,
  })
  @IsInt()
  @Min(1)
  quantity: number;
}

// Alias for backward compatibility
export { UpdateCartItemDto as UpdateCartItemQuantityDto };

export class CartItemResponseDto {
  @ApiProperty({
    description: 'Cart item ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  id: string;

  @ApiProperty({
    description: 'Product variant ID',
    example: '550e8400-e29b-41d4-a716-446655440001',
  })
  productVariantId: string;

  @ApiProperty({
    description: 'Product ID',
    example: '550e8400-e29b-41d4-a716-446655440002',
  })
  productId: string;

  @ApiProperty({
    description: 'Product name',
    example: 'Adjustable Dumbbells',
  })
  name: string;

  @ApiProperty({
    description: 'Unit price',
    example: 299.99,
  })
  price: number;

  @ApiProperty({
    description: 'Quantity',
    example: 2,
  })
  quantity: number;

  @ApiProperty({
    description: 'Total price',
    example: 599.98,
  })
  totalPrice: number;

  @ApiProperty({
    description: 'Is the item in stock',
    example: true,
  })
  inStock: boolean;

  @ApiProperty({
    description: 'Product image URL',
    example: 'https://example.com/image.jpg',
    required: false,
  })
  @IsOptional()
  imageUrl?: string;

  @ApiProperty({
    description: 'Color name',
    example: 'Black',
    required: false,
  })
  @IsOptional()
  color?: string | null;

  @ApiProperty({
    description: 'Size name',
    example: 'Medium',
    required: false,
  })
  @IsOptional()
  size?: string | null;
}
