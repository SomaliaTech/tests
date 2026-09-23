// src/affiliate/dto/affiliate-settings.dto.ts
import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  Max,
  Min,
} from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateAffiliateSettingsDto {
  // Commission
  @ApiPropertyOptional({ example: 5.0 })
  @IsNumber()
  @Min(0)
  @Max(100)
  @IsOptional()
  defaultCommissionRate?: number;

  @ApiPropertyOptional({ example: 10.0 })
  @IsNumber()
  @Min(0)
  @IsOptional()
  minPayoutAmount?: number;

  @ApiPropertyOptional({ example: 30 })
  @IsInt()
  @Min(1)
  @Max(365)
  @IsOptional()
  payoutCycleDays?: number;

  // Promo code
  @ApiPropertyOptional({ enum: ['PERCENTAGE', 'FIXED'] })
  @IsEnum(['PERCENTAGE', 'FIXED'])
  @IsOptional()
  defaultDiscountType?: 'PERCENTAGE' | 'FIXED';

  @ApiPropertyOptional({ example: 5.0 })
  @IsNumber()
  @Min(0)
  @IsOptional()
  defaultDiscountValue?: number;

  @ApiPropertyOptional({ example: 1 })
  @IsInt()
  @Min(1)
  @Max(100)
  @IsOptional()
  defaultMaxUsesPerUser?: number;

  // Program rules
  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  requireApproval?: boolean;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  autoApprovePromoCodes?: boolean;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  allowSelfReferral?: boolean;

  @ApiPropertyOptional({ example: 30 })
  @IsInt()
  @Min(1)
  @Max(365)
  @IsOptional()
  cookieWindowDays?: number;

  // Notifications
  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  notifyOnNewApplication?: boolean;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  notifyOnNewCommission?: boolean;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  notifyOnCodeApproval?: boolean;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  emailDigest?: boolean;
}
