// dto/create-product.dto.ts

import {
  IsString,
  IsOptional,
  IsNumber,
  IsBoolean,
  IsArray,
  ValidateNested,
  Min,
  IsUUID,
  IsInt,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

// ==========================================
// CREATE PRODUCT DTOs
// ==========================================

export class CreateProductVariantDto {
  @ApiPropertyOptional({
    description:
      'Color ID (optional - can be null for products without color options)',
    example: '550e8400-e29b-41d4-a716-446655440001',
  })
  @IsUUID()
  @IsOptional()
  colorId?: string | null;

  @ApiPropertyOptional({
    description:
      'Size ID (optional - can be null for products without size options)',
    example: '550e8400-e29b-41d4-a716-446655440002',
  })
  @IsUUID()
  @IsOptional()
  sizeId?: string | null;

  @ApiPropertyOptional({
    description: 'SKU (auto-generated if not provided)',
    example: 'PROD-COLOR-SIZE',
  })
  @IsString()
  @IsOptional()
  sku?: string;

  @ApiProperty({
    description: 'Stock quantity',
    example: 50,
  })
  @IsInt()
  @Min(0)
  stock: number;

  @ApiPropertyOptional({
    description: 'Variant price (uses product price if not provided)',
    example: 1299.99,
  })
  @IsNumber()
  @IsOptional()
  price?: number;
}

export class CreateProductDto {
  @ApiProperty({ description: 'Product name', example: 'Apple iPhone 15 Pro' })
  @IsString()
  name: string;

  @ApiPropertyOptional({
    description: 'Product slug (auto-generated if not provided)',
  })
  @IsString()
  @IsOptional()
  slug?: string;

  @ApiPropertyOptional({ description: 'Product description' })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiProperty({ description: 'Product price', example: 1299.99 })
  @IsNumber()
  @Min(0)
  price: number;

  @ApiPropertyOptional({ description: 'Stock quantity', example: 100 })
  @IsNumber()
  @Min(0)
  @IsOptional()
  stock?: number;

  @ApiProperty({ description: 'Category ID' })
  @IsString()
  categoryId: string;

  @ApiPropertyOptional({
    description: 'Whether the product is active',
    default: true,
  })
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @ApiPropertyOptional({
    description: 'Whether the product is featured',
    default: false,
  })
  @IsBoolean()
  @IsOptional()
  isFeatured?: boolean;

  @ApiPropertyOptional({ description: 'SKU' })
  @IsString()
  @IsOptional()
  sku?: string;

  @ApiPropertyOptional({ description: 'Barcode' })
  @IsString()
  @IsOptional()
  barcode?: string;

  @ApiPropertyOptional({ description: 'Brand name' })
  @IsString()
  @IsOptional()
  brand?: string;

  @ApiPropertyOptional({ description: 'Tags (comma-separated)' })
  @IsString()
  @IsOptional()
  tags?: string;

  @ApiPropertyOptional({ description: 'SEO Title' })
  @IsString()
  @IsOptional()
  seoTitle?: string;

  @ApiPropertyOptional({ description: 'SEO Description' })
  @IsString()
  @IsOptional()
  seoDescription?: string;

  @ApiPropertyOptional({
    description: 'Compare at price (original price)',
    example: 1499.99,
  })
  @IsNumber()
  @IsOptional()
  compareAtPrice?: number;

  @ApiPropertyOptional({ description: 'Cost per item', example: 800.0 })
  @IsNumber()
  @IsOptional()
  costPerItem?: number;

  @ApiPropertyOptional({ description: 'Product weight (kg)', example: 0.5 })
  @IsNumber()
  @IsOptional()
  weight?: number;

  @ApiPropertyOptional({
    description: 'Product variants',
    type: [CreateProductVariantDto],
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateProductVariantDto)
  @IsOptional()
  variants?: CreateProductVariantDto[];

  @ApiPropertyOptional({
    description: 'Image URLs',
    example: ['https://example.com/image1.jpg'],
  })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  imageUrls?: string[];
}

export class UploadBase64ImageDto {
  @ApiProperty({ description: 'Base64 encoded image' })
  @IsString()
  base64Image: string;
}

// ==========================================
// PRODUCT RESPONSE DTOs (FIXED)
// ==========================================

// Image Response DTO
export class ProductImageResponseDto {
  @ApiProperty({ description: 'Image unique ID' })
  @IsUUID()
  id: string;

  @ApiProperty({ description: 'Image URL' })
  @IsString()
  url: string;

  @ApiProperty({ description: 'Image public ID' })
  @IsString()
  publicId: string;

  @ApiPropertyOptional({ description: 'Whether this is the main image' })
  @IsOptional()
  @IsBoolean()
  isMain?: boolean;

  @ApiPropertyOptional({ description: 'Alt text for the image' })
  @IsOptional()
  @IsString()
  altText?: string;

  @ApiPropertyOptional({ description: 'Display order' })
  @IsOptional()
  @IsInt()
  order?: number;
}

// Color Response DTO
export class ColorResponseDto {
  @ApiProperty({ description: 'Color unique ID' })
  @IsUUID()
  id: string;

  @ApiProperty({ description: 'Color name' })
  @IsString()
  name: string;

  @ApiProperty({ description: 'Color hex code' })
  @IsString()
  code: string;
}

// Size Response DTO
export class SizeResponseDto {
  @ApiProperty({ description: 'Size unique ID' })
  @IsUUID()
  id: string;

  @ApiProperty({ description: 'Size name' })
  @IsString()
  name: string;

  @ApiProperty({ description: 'Size value' })
  @IsString()
  value: string;
}

// Product Variant Response DTO
export class ProductVariantResponseDto {
  @ApiProperty({ description: 'Variant unique ID' })
  @IsUUID()
  id: string;

  @ApiProperty({ description: 'Product ID' })
  @IsUUID()
  productId: string;

  @ApiPropertyOptional({ description: 'Color' })
  @IsOptional()
  @Type(() => ColorResponseDto)
  color?: ColorResponseDto | null;

  @ApiPropertyOptional({ description: 'Size' })
  @IsOptional()
  @Type(() => SizeResponseDto)
  size?: SizeResponseDto | null;

  @ApiPropertyOptional({ description: 'Color ID' })
  @IsOptional()
  @IsUUID()
  colorId?: string | null;

  @ApiPropertyOptional({ description: 'Size ID' })
  @IsOptional()
  @IsUUID()
  sizeId?: string | null;

  @ApiPropertyOptional({ description: 'Variant SKU' })
  @IsOptional()
  @IsString()
  sku?: string | null;

  @ApiProperty({ description: 'Stock quantity' })
  @IsInt()
  stock: number;

  @ApiPropertyOptional({ description: 'Variant price' })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  price?: number | null;

  @ApiProperty({ description: 'Creation date' })
  @IsString()
  createdAt: Date;

  @ApiProperty({ description: 'Last update date' })
  @IsString()
  updatedAt: Date;

  // Derived fields
  @ApiPropertyOptional({ description: 'Color name' })
  @IsOptional()
  @IsString()
  colorName?: string | null;

  @ApiPropertyOptional({ description: 'Size name' })
  @IsOptional()
  @IsString()
  sizeName?: string | null;
}

// Category Response DTO
export class CategoryResponseDto {
  @ApiProperty({ description: 'Category unique ID' })
  @IsUUID()
  id: string;

  @ApiProperty({ description: 'Category name' })
  @IsString()
  name: string;

  @ApiProperty({ description: 'Category slug' })
  @IsString()
  slug: string;

  @ApiPropertyOptional({ description: 'Category description' })
  @IsOptional()
  @IsString()
  description?: string | null;

  @ApiPropertyOptional({ description: 'Parent category ID' })
  @IsOptional()
  @IsUUID()
  parentId?: string | null;

  @ApiProperty({ description: 'Whether the category is active' })
  @IsBoolean()
  isActive: boolean;

  @ApiProperty({ description: 'Creation date' })
  @IsString()
  createdAt: Date;

  @ApiProperty({ description: 'Last update date' })
  @IsString()
  updatedAt: Date;
}

// ✅ MAIN PRODUCT RESPONSE DTO WITH FIXED RATING TYPES
// In create-product.dto.ts - update ProductResponseDto

export class ProductResponseDto {
  @ApiProperty({ description: 'Product unique ID' })
  @IsUUID()
  id: string;

  @ApiProperty({ description: 'Product name' })
  @IsString()
  name: string;

  @ApiPropertyOptional({ description: 'Product slug' })
  @IsOptional()
  @IsString()
  slug?: string | null; // ✅ Make it optional and nullable

  @ApiPropertyOptional({ description: 'Product description' })
  @IsOptional()
  @IsString()
  description?: string | null;

  @ApiProperty({ description: 'Product price' })
  @IsNumber()
  @Type(() => Number)
  price: number;

  @ApiPropertyOptional({ description: 'Compare at price' })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  compareAtPrice?: number | null;

  @ApiPropertyOptional({ description: 'Cost per item' })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  costPerItem?: number | null;

  @ApiProperty({ description: 'Stock quantity' })
  @IsInt()
  stock: number;

  @ApiPropertyOptional({ description: 'SKU' })
  @IsOptional()
  @IsString()
  sku?: string | null;

  @ApiPropertyOptional({ description: 'Barcode' })
  @IsOptional()
  @IsString()
  barcode?: string | null;

  @ApiPropertyOptional({ description: 'Weight' })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  weight?: number | null;

  @ApiPropertyOptional({ description: 'Brand name' })
  @IsOptional()
  @IsString()
  brand?: string | null;

  @ApiProperty({ description: 'Whether the product is active' })
  @IsBoolean()
  isActive: boolean;

  @ApiProperty({ description: 'Whether the product is featured' })
  @IsBoolean()
  isFeatured: boolean;

  @ApiProperty({ description: 'Category ID' })
  @IsUUID()
  categoryId: string;

  @ApiPropertyOptional({ description: 'Tags' })
  @IsOptional()
  @IsString()
  tags?: string | null;

  @ApiPropertyOptional({ description: 'SEO Title' })
  @IsOptional()
  @IsString()
  seoTitle?: string | null;

  @ApiPropertyOptional({ description: 'SEO Description' })
  @IsOptional()
  @IsString()
  seoDescription?: string | null;

  @ApiProperty({ description: 'Creation date' })
  @IsString()
  createdAt: Date;

  @ApiProperty({ description: 'Last update date' })
  @IsString()
  updatedAt: Date;

  // ✅ FIXED: rating as number
  @ApiProperty({
    description: 'Product rating (average of all reviews)',
    example: 4.5,
    type: Number,
  })
  @IsNumber()
  @Type(() => Number)
  rating: number;

  // ✅ FIXED: reviewCount as number
  @ApiProperty({
    description: 'Total number of reviews',
    example: 42,
    type: Number,
  })
  @IsInt()
  @Type(() => Number)
  reviewCount: number;

  // Relations
  @ApiPropertyOptional({ description: 'Product category' })
  @IsOptional()
  @Type(() => CategoryResponseDto)
  category?: CategoryResponseDto | null;

  @ApiPropertyOptional({
    description: 'Product images',
    type: [ProductImageResponseDto],
  })
  @IsOptional()
  @IsArray()
  @Type(() => ProductImageResponseDto)
  images?: ProductImageResponseDto[];

  @ApiPropertyOptional({
    description: 'Product variants',
    type: [ProductVariantResponseDto],
  })
  @IsOptional()
  @IsArray()
  @Type(() => ProductVariantResponseDto)
  variants?: ProductVariantResponseDto[];
}

// ✅ PAGINATED PRODUCT RESPONSE DTO
export class PaginatedProductsResponseDto {
  @ApiProperty({ description: 'List of products', type: [ProductResponseDto] })
  @IsArray()
  @Type(() => ProductResponseDto)
  products: ProductResponseDto[];

  @ApiProperty({ description: 'Total number of products', example: 100 })
  @IsInt()
  total: number;

  @ApiProperty({ description: 'Current page number', example: 1 })
  @IsInt()
  page: number;

  @ApiProperty({ description: 'Number of products per page', example: 20 })
  @IsInt()
  limit: number;

  @ApiProperty({ description: 'Total number of pages', example: 5 })
  @IsInt()
  totalPages: number;
}

// ✅ PRODUCT FILTERS DTO
export class ProductFiltersDto {
  @ApiPropertyOptional({ description: 'Sort by field' })
  @IsOptional()
  @IsString()
  sortBy?: string;

  @ApiPropertyOptional({ description: 'Number of products per page' })
  @IsOptional()
  @IsInt()
  @Min(1)
  limit?: number;

  @ApiPropertyOptional({ description: 'Page number' })
  @IsOptional()
  @IsInt()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ description: 'Minimum price filter' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  minPrice?: number;

  @ApiPropertyOptional({ description: 'Maximum price filter' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  maxPrice?: number;

  @ApiPropertyOptional({ description: 'Category ID filter' })
  @IsOptional()
  @IsUUID()
  categoryId?: string;
}
