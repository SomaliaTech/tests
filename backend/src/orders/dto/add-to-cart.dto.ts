import { ApiProperty } from '@nestjs/swagger';
import { IsUUID, IsInt, Min } from 'class-validator';

export class AddToCartDto {
  @ApiProperty({
    description: 'Product variant UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsUUID()
  productVariantId: string;

  @ApiProperty({
    description: 'Quantity to add to cart',
    example: 2,
    minimum: 1,
  })
  @IsInt()
  @Min(1)
  quantity: number;
}
