// src/affiliate/dto/affiliate.dto.ts
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
  IsEnum,
  IsDateString,
  Max,
  IsNotEmpty,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

// ==========================================
// USER - Apply for Affiliate
// ==========================================
export class ApplyAffiliateDto {
  @ApiProperty({ example: 'Ina Libaax Marketing' })
  @IsString()
  businessName!: string;

  @ApiPropertyOptional({ example: 'I have 50K followers...' })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiPropertyOptional({ example: '+252617541182' })
  @IsString()
  @IsOptional()
  phoneNumber?: string;

  @ApiPropertyOptional({ example: { instagram: '@inalibaax' } })
  @IsOptional()
  socialMediaLinks?: Record<string, string>; // ⚠️ No validator

  @ApiPropertyOptional({ example: 50000 })
  @IsInt()
  @Min(0)
  @IsOptional()
  expectedAudience?: number;
}
// ==========================================
// USER - Create Promo Code
// ==========================================
export class CreatePromoCodeDto {
  @ApiProperty({ example: 'INA2026' })
  @IsString()
  code!: string; // ✅ Added !

  @ApiPropertyOptional({ example: 'Get 10% off!' })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiProperty({ enum: ['PERCENTAGE', 'FIXED'], example: 'PERCENTAGE' })
  @IsEnum(['PERCENTAGE', 'FIXED'])
  discountType!: 'PERCENTAGE' | 'FIXED'; // ✅ Added !

  @ApiProperty({ example: 10 })
  @IsNumber()
  @Min(0)
  discountValue!: number; // ✅ Added !

  @ApiPropertyOptional({ example: 50 })
  @IsNumber()
  @Min(0)
  @IsOptional()
  minOrderAmount?: number;

  @ApiPropertyOptional({ example: 100 })
  @IsNumber()
  @Min(0)
  @IsOptional()
  maxDiscountAmount?: number;

  @ApiPropertyOptional({ example: 1000 })
  @IsInt()
  @Min(1)
  @IsOptional()
  maxUses?: number;

  @ApiPropertyOptional({ example: 3 })
  @IsInt()
  @Min(1)
  @IsOptional()
  maxUsesPerUser?: number;

  @ApiPropertyOptional({ example: '2026-12-31T23:59:59.000Z' })
  @IsDateString()
  @IsOptional()
  expiresAt?: string;
}

// ==========================================
// USER - Validate Promo Code
// ==========================================
export class ValidatePromoCodeDto {
  @ApiProperty({ description: 'Promo code to validate', example: 'SAVE20' })
  @IsString()
  @IsNotEmpty()
  code!: string;

  @ApiProperty({ description: 'Total order amount', example: 150.0 })
  @IsNumber()
  @Min(0)
  orderAmount!: number;
}

// ==========================================
// ADMIN - Review Affiliate Request
// ==========================================
export class ReviewAffiliateRequestDto {
  @ApiPropertyOptional({ example: 'Approved!' })
  @IsString()
  @IsOptional()
  note?: string;

  @ApiPropertyOptional({ example: 5.0 })
  @IsNumber()
  @Min(0)
  @Max(100)
  @IsOptional()
  commissionRate?: number;
}

export class RejectAffiliateRequestDto {
  @ApiProperty({ example: 'Insufficient social media presence' })
  @IsString()
  rejectionReason!: string; // ✅ Added !
}

// ==========================================
// ADMIN - Update Affiliate
// ==========================================
export class UpdateAffiliateDto {
  @ApiPropertyOptional({ example: 7.5 })
  @IsNumber()
  @Min(0)
  @Max(100)
  @IsOptional()
  commissionRate?: number;

  @ApiPropertyOptional({ enum: ['ACTIVE', 'SUSPENDED'] })
  @IsEnum(['ACTIVE', 'SUSPENDED'])
  @IsOptional()
  status?: 'ACTIVE' | 'SUSPENDED';
}

// ==========================================
// ADMIN - Update Promo Code
// ==========================================
export class UpdatePromoCodeDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  description?: string;

  @ApiPropertyOptional({ enum: ['PERCENTAGE', 'FIXED'] })
  @IsEnum(['PERCENTAGE', 'FIXED'])
  @IsOptional()
  discountType?: 'PERCENTAGE' | 'FIXED';

  @ApiPropertyOptional()
  @IsNumber()
  @Min(0)
  @IsOptional()
  discountValue?: number;

  @ApiPropertyOptional()
  @IsNumber()
  @Min(0)
  @IsOptional()
  minOrderAmount?: number;

  @ApiPropertyOptional()
  @IsNumber()
  @Min(0)
  @IsOptional()
  maxDiscountAmount?: number;

  @ApiPropertyOptional()
  @IsInt()
  @Min(1)
  @IsOptional()
  maxUses?: number;

  @ApiPropertyOptional()
  @IsInt()
  @Min(1)
  @IsOptional()
  maxUsesPerUser?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  // ✅ ALLOW null to clear the expiry
  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsDateString()
  expiresAt?: string | null;
}
// ==========================================
// ADMIN - Pay Commission
// ==========================================x
export class PayCommissionDto {
  @ApiProperty({ type: [String] })
  @IsUUID('4', { each: true })
  commissionIds!: string[]; // ✅ Added !

  @ApiPropertyOptional({ example: 'Paid via EVC Plus' })
  @IsString()
  @IsOptional()
  paymentNote?: string;
}
