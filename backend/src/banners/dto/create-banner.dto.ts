// create-banner.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsBoolean,
  IsNumber,
  IsUrl,
  IsDateString,
  Matches,
  Min,
  Max,
} from 'class-validator';

export class CreateBannerDto {
  @ApiProperty({ description: 'Banner title' })
  @IsString()
  title: string;

  @ApiProperty({ description: 'Banner subtitle', required: false })
  @IsOptional()
  @IsString()
  subtitle?: string;

  @ApiProperty({ description: 'Banner image URL' })
  @IsUrl()
  imageUrl: string;

  @ApiProperty({ description: 'Button text', required: false })
  @IsOptional()
  @IsString()
  buttonText?: string;

  @ApiProperty({ description: 'Action link URL', required: false })
  @IsOptional()
  @IsString()
  actionLink?: string;

  @ApiProperty({ description: 'Background color (hex)', required: false })
  @IsOptional()
  @Matches(/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/, {
    message: 'Invalid hex color format',
  })
  backgroundColor?: string;

  @ApiProperty({ description: 'Gradient start color (hex)', required: false })
  @IsOptional()
  @Matches(/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/, {
    message: 'Invalid hex color format',
  })
  gradientStart?: string;

  @ApiProperty({ description: 'Gradient end color (hex)', required: false })
  @IsOptional()
  @Matches(/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/, {
    message: 'Invalid hex color format',
  })
  gradientEnd?: string;

  @ApiProperty({ description: 'Is banner active', default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @ApiProperty({ description: 'Display order', default: 0 })
  @IsOptional()
  @IsNumber()
  order?: number;

  // ✅ Discount fields
  @ApiProperty({ description: 'Has discount', default: false })
  @IsOptional()
  @IsBoolean()
  hasDiscount?: boolean;

  @ApiProperty({ description: 'Discount percentage (0-100)', required: false })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  discountPercentage?: number;

  @ApiProperty({ description: 'Discount amount in dollars', required: false })
  @IsOptional()
  @IsNumber()
  @Min(0)
  discountAmount?: number;

  @ApiProperty({ description: 'Discount code', required: false })
  @IsOptional()
  @IsString()
  discountCode?: string;

  @ApiProperty({ description: 'Discount start date', required: false })
  @IsOptional()
  @IsDateString()
  discountStartDate?: string;

  @ApiProperty({ description: 'Discount end date', required: false })
  @IsOptional()
  @IsDateString()
  discountEndDate?: string;

  // ✅ Flash sale fields
  @ApiProperty({ description: 'Is flash sale', default: false })
  @IsOptional()
  @IsBoolean()
  isFlashSale?: boolean;

  @ApiProperty({ description: 'Flash sale start time', required: false })
  @IsOptional()
  @IsDateString()
  flashSaleStartTime?: string;

  @ApiProperty({ description: 'Flash sale end time', required: false })
  @IsOptional()
  @IsDateString()
  flashSaleEndTime?: string;

  @ApiProperty({ description: 'Flash sale quantity limit', required: false })
  @IsOptional()
  @IsNumber()
  @Min(1)
  flashSaleQuantity?: number;

  @ApiProperty({ description: 'Flash sale price', required: false })
  @IsOptional()
  @IsNumber()
  @Min(0)
  flashSalePrice?: number;
}
