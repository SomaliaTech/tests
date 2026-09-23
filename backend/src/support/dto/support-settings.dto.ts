// src/support/dto/support-settings.dto.ts
import {
  IsEmail,
  IsOptional,
  IsString,
  Matches,
  MinLength,
} from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateSupportSettingsDto {
  @ApiPropertyOptional({ example: 'support@farxada.com' })
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiPropertyOptional({ example: '8080' })
  @IsString()
  @MinLength(4, { message: 'phoneNumber must be at least 4 characters' })
  @Matches(/^[0-9+\-() ]+$/, {
    message: 'phoneNumber must contain only digits, +, -, (), or spaces',
  })
  @IsOptional()
  phoneNumber?: string;
}
