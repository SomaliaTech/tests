// src/admin/dto/create-product-admin.dto.ts
import { ApiProperty } from '@nestjs/swagger';
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
  colorId: string;

  @IsUUID()
  @ApiProperty({ description: 'Size ID' })
  sizeId: string;

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false, description: 'SKU' })
  sku?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @ApiProperty({ required: false, description: 'Stock quantity' })
  stock?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @ApiProperty({ required: false, description: 'Variant price' })
  price?: number;
}

export class CreateProductAdminDto {
  @IsString()
  @ApiProperty({ description: 'Product name' })
  name: string;

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false, description: 'Product slug' })
  slug?: string;

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false, description: 'Product description' })
  description?: string;

  @IsNumber()
  @Min(0)
  @ApiProperty({ description: 'Product price' })
  price: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @ApiProperty({ required: false, description: 'Compare at price' })
  compareAtPrice?: number | null;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @ApiProperty({ required: false, description: 'Cost per item' })
  costPerItem?: number | null;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @ApiProperty({ required: false, description: 'Stock quantity' })
  stock?: number;

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false, description: 'SKU' })
  sku?: string;

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false, description: 'Barcode' })
  barcode?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @ApiProperty({ required: false, description: 'Weight' })
  weight?: number | null;

  @IsUUID()
  @ApiProperty({ description: 'Category ID' })
  categoryId: string;

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false, description: 'Brand' })
  brand?: string;

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false, description: 'Tags' })
  tags?: string;

  @IsOptional()
  @IsBoolean()
  @ApiProperty({ required: false, description: 'Is active' })
  isActive?: boolean;

  @IsOptional()
  @IsBoolean()
  @ApiProperty({ required: false, description: 'Is featured' })
  isFeatured?: boolean;

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false, description: 'SEO Title' })
  seoTitle?: string;

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false, description: 'SEO Description' })
  seoDescription?: string;

  @IsOptional()
  @ApiProperty({
    required: false,
    type: [CreateVariantDto],
    description: 'Product variants',
  })
  variants?: CreateVariantDto[];
}
