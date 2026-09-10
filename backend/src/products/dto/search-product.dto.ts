import {
  IsOptional,
  IsString,
  IsNumber,
  IsUUID,
  Min,
  Max,
  IsBoolean,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class SearchProductDto {
  @IsString()
  @IsOptional()
  search?: string;

  @IsUUID()
  @IsOptional()
  categoryId?: string;

  @Type(() => Number)
  @IsNumber()
  @IsOptional()
  @Min(0)
  minPrice?: number;

  @Type(() => Number)
  @IsNumber()
  @IsOptional()
  @Min(0)
  maxPrice?: number;

  @IsString()
  @IsOptional()
  brand?: string;

  @IsString()
  @IsOptional()
  sortBy?: 'price_asc' | 'price_desc' | 'newest' | 'popular';

  @Type(() => Number)
  @IsNumber()
  @IsOptional()
  @Min(1)
  page?: number;

  @Type(() => Number)
  @IsNumber()
  @IsOptional()
  @Min(1)
  @Max(100)
  limit?: number;
  @ApiPropertyOptional({
    description: 'Whether the product is featured/hot',
    default: false,
  })
  @IsBoolean()
  @IsOptional()
  isFeatured?: boolean; // ✅ ADD THIS
}
