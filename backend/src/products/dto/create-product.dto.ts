import {
  IsString,
  IsOptional,
  IsDecimal,
  IsInt,
  IsBoolean,
  IsUUID,
  IsArray,
  IsUrl,
  Min,
  MaxLength,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateProductDto {
  @IsString()
  @MaxLength(255)
  name!: string;

  @IsString()
  @MaxLength(255)
  slug!: string;

  @IsString()
  @IsOptional()
  description?: string;

  @Type(() => Number)
  @IsDecimal()
  price!: number;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  stock!: number;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @IsUUID()
  categoryId!: string;

  @IsArray()
  @IsOptional()
  @IsUrl({}, { each: true })
  imageUrls?: string[];
}

export class CreateProductVariantDto {
  @IsUUID()
  colorId!: string;

  @IsUUID()
  sizeId!: string;

  @IsString()
  sku!: string;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  stock!: number;

  @Type(() => Number)
  @IsOptional()
  @IsDecimal()
  price?: number;
}

export class UploadImageDto {
  @IsUrl()
  imageUrl!: string;
}

export class UploadBase64ImageDto {
  @IsString()
  base64Image!: string;
}
