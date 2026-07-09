// src/admin/dto/create-proudct-admin-dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNumber,
  IsOptional,
  IsUUID,
  IsBoolean,
  Min,
} from 'class-validator';

export class CreateVariantDto {
  @IsUUID()
  @ApiProperty({ description: 'Color ID' })
  colorId!: string;

  @IsUUID()
  @ApiProperty({ description: 'Size ID' })
  sizeId!: string;

  @IsOptional()
  @IsString()
  @ApiPropertyOptional({ description: 'SKU' })
  sku?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @ApiPropertyOptional({ description: 'Stock quantity' })
  stock?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @ApiPropertyOptional({ description: 'Variant price' })
  price?: number;
}

export class CreateProductAdminDto {
  @IsString()
  @ApiProperty({ description: 'Product name' })
  name!: string;

  @IsOptional()
  @IsString()
  @ApiPropertyOptional({ description: 'Product slug' })
  slug?: string;

  @IsOptional()
  @IsString()
  @ApiPropertyOptional({ description: 'Product description' })
  description?: string;

  @IsNumber()
  @Min(0)
  @ApiProperty({ description: 'Product price' })
  price!: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @ApiPropertyOptional({ description: 'Compare at price' })
  compareAtPrice?: number | null;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @ApiPropertyOptional({ description: 'Cost per item' })
  costPerItem?: number | null;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @ApiPropertyOptional({ description: 'Stock quantity' })
  stock?: number;

  @IsOptional()
  @IsString()
  @ApiPropertyOptional({ description: 'SKU' })
  sku?: string;

  @IsOptional()
  @IsString()
  @ApiPropertyOptional({ description: 'Barcode' })
  barcode?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @ApiPropertyOptional({ description: 'Weight' })
  weight?: number | null;

  @IsUUID()
  @ApiProperty({ description: 'Category ID' })
  categoryId!: string;

  @IsOptional()
  @IsString()
  @ApiPropertyOptional({ description: 'Brand' })
  brand?: string;

  @IsOptional()
  @IsString()
  @ApiPropertyOptional({ description: 'Tags' })
  tags?: string;

  @IsOptional()
  @IsBoolean()
  @ApiPropertyOptional({ description: 'Is active' })
  isActive?: boolean;

  @IsOptional()
  @IsBoolean()
  @ApiPropertyOptional({ description: 'Is featured' })
  isFeatured?: boolean;

  @IsOptional()
  @IsString()
  @ApiPropertyOptional({ description: 'SEO Title' })
  seoTitle?: string;

  @IsOptional()
  @IsString()
  @ApiPropertyOptional({ description: 'SEO Description' })
  seoDescription?: string;

  @IsOptional()
  @ApiPropertyOptional({
    type: [CreateVariantDto],
    description: 'Product variants',
  })
  variants?: CreateVariantDto[];
}
// src/admin/dto/create-proudct-admin-dto.ts (or update-product.dto.ts)

export class UpdateProductAdminDto {
  @ApiProperty({ required: false })
  name?: string;

  @ApiProperty({ required: false })
  description?: string;

  @ApiProperty({ required: false })
  price?: number;

  @ApiProperty({ required: false })
  stock?: number;

  @ApiProperty({ required: false })
  categoryId?: string;

  @ApiProperty({ required: false })
  brand?: string;

  @ApiProperty({ required: false })
  tags?: string;

  @ApiProperty({ required: false })
  isActive?: boolean;

  // ✅ New fields for variant/image management
  @ApiProperty({ required: false, type: [String] })
  deleted_image_ids?: string[];

  @ApiProperty({ required: false, type: [String] })
  deleted_variant_ids?: string[];

  @ApiProperty({ required: false, type: [Object] })
  existing_variants?: Array<{
    variantId?: string;
    id?: string;
    colorId?: string;
    sizeId?: string;
    sku?: string;
    stock?: number;
    price?: number;
  }>;

  @ApiProperty({ required: false, type: [Object] })
  new_variants?: Array<{
    colorId: string;
    sizeId: string;
    sku?: string;
    stock?: number;
    price?: number;
  }>;
}
