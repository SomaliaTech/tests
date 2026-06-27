import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsInt,
  Min,
  IsUUID,
  IsNotEmpty,
  IsOptional,
  IsBoolean,
  IsNumber,
} from 'class-validator';

// ==========================================
// ADD TO CART DTO
// ==========================================

export class AddToCartDto {
  @ApiProperty({
    description: 'Product ID (Required - always needed)',
    example: '550e8400-e29b-41d4-a716-446655440002',
  })
  @IsUUID()
  @IsNotEmpty()
  productId: string;

  @ApiPropertyOptional({
    description:
      'Product variant ID (Optional - only required if product has variants like color/size)',
    example: '550e8400-e29b-41d4-a716-446655440001',
  })
  @IsUUID()
  @IsOptional()
  productVariantId?: string;

  @ApiProperty({
    description: 'Quantity to add to cart',
    minimum: 1,
    default: 1,
    example: 2,
  })
  @IsInt()
  @Min(1)
  quantity: number = 1;
}

// Alias for backward compatibility
export { AddToCartDto as AddProductToCartDto };

// ==========================================
// UPDATE CART ITEM DTO
// ==========================================

export class UpdateCartItemDto {
  @ApiProperty({
    description: 'New quantity for the cart item',
    example: 3,
    minimum: 1,
  })
  @IsInt()
  @Min(1)
  quantity: number;
}

// Alias for backward compatibility
export { UpdateCartItemDto as UpdateCartItemQuantityDto };

// ==========================================
// CART ITEM RESPONSE DTO
// ==========================================

export class CartItemResponseDto {
  @ApiProperty({
    description: 'Cart item unique ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  id: string;

  @ApiProperty({
    description: 'Product ID (always present)',
    example: '550e8400-e29b-41d4-a716-446655440002',
  })
  productId: string;

  @ApiPropertyOptional({
    description: 'Product variant ID (null if product has no variants)',
    example: '550e8400-e29b-41d4-a716-446655440001',
    nullable: true,
  })
  productVariantId: string | null;

  @ApiProperty({
    description: 'Product name',
    example: 'Adjustable Dumbbells',
  })
  name: string;

  @ApiProperty({
    description:
      'Unit price (uses variant price if available, otherwise product price)',
    example: 299.99,
  })
  price: number;

  @ApiProperty({
    description: 'Current quantity in cart',
    example: 2,
  })
  quantity: number;

  @ApiProperty({
    description: 'Total price for this cart item (price × quantity)',
    example: 599.98,
  })
  totalPrice: number;

  @ApiProperty({
    description: 'Maximum available stock for this item',
    example: 50,
  })
  @IsInt()
  maxStock: number;

  @ApiProperty({
    description: 'Whether the item is currently in stock',
    example: true,
  })
  inStock: boolean;

  @ApiPropertyOptional({
    description:
      'Indicates if this cart item has a variant (color/size) or is a base product',
    example: false,
  })
  hasVariant: boolean;

  @ApiPropertyOptional({
    description: 'Product image URL',
    example: 'https://example.com/products/dumbbells.jpg',
  })
  @IsOptional()
  imageUrl?: string;

  @ApiPropertyOptional({
    description: 'Selected color name (only if variant exists)',
    example: 'Black',
    nullable: true,
  })
  @IsOptional()
  color?: string | null;

  @ApiPropertyOptional({
    description: 'Selected size name (only if variant exists)',
    example: 'Medium',
    nullable: true,
  })
  @IsOptional()
  size?: string | null;
}

// ==========================================
// CART RESPONSE DTO (Complete cart)
// ==========================================

export class CartResponseDto {
  @ApiProperty({
    description: 'Array of cart items',
    type: [CartItemResponseDto],
  })
  items: CartItemResponseDto[];

  @ApiProperty({
    description: 'Total cart subtotal (sum of all items)',
    example: 899.97,
  })
  @IsNumber()
  subtotal: number;

  @ApiProperty({
    description: 'Total number of items in cart (sum of quantities)',
    example: 5,
  })
  @IsInt()
  itemCount: number;

  @ApiProperty({
    description: 'Total quantity of all items',
    example: 5,
  })
  @IsInt()
  totalQuantity: number;

  @ApiProperty({
    description: 'Whether all items in cart are in stock',
    example: true,
  })
  @IsBoolean()
  allInStock: boolean;
}

// ==========================================
// REMOVE CART ITEM RESPONSE DTO
// ==========================================

export class RemoveCartItemResponseDto {
  @ApiProperty({
    description: 'Success message',
    example: 'Cart item removed successfully',
  })
  message: string;
}

// ==========================================
// CLEAR CART RESPONSE DTO
// ==========================================

export class ClearCartResponseDto {
  @ApiProperty({
    description: 'Success message',
    example: 'Cart cleared successfully',
  })
  message: string;
}
