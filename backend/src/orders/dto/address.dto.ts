// src/orders/dto/address.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsBoolean,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

export class AddressDto {
  @ApiProperty({
    description: 'Address label (e.g., Home, Office)',
    example: 'Home',
    maxLength: 50,
  })
  @IsString()
  @MaxLength(50)
  label: string;

  @ApiProperty({
    description: 'Full street address',
    example: '123 Main Street, Mogadishu, Somalia',
    maxLength: 500,
  })
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  fullAddress: string;

  @ApiProperty({
    description: 'Phone number (accepts both Somali and international formats)',
    example: '+15551234567',
    examples: {
      somali: {
        value: '+252612345678',
        description: 'Somali number with +252 prefix',
      },
      international: {
        value: '+15551234567',
        description: 'International number with +1 prefix',
      },
      noPlus: {
        value: '15551234567',
        description: 'International number without + prefix',
      },
      withSpaces: {
        value: '+1 555 123 4567',
        description: 'International number with spaces',
      },
    },
  })
  @IsString()
  @MinLength(7, { message: 'Phone number must be at least 7 characters' })
  @MaxLength(20, { message: 'Phone number must be at most 20 characters' })
  @Matches(/^\+?[0-9\s-]{7,20}$/, {
    message:
      'Phone number must be a valid phone number (7-20 digits, can include +, spaces, or dashes)',
  })
  phoneNumber: string;

  @ApiProperty({
    description: 'Set as default address',
    example: true,
    required: false,
  })
  @IsBoolean()
  @IsOptional()
  isDefault?: boolean;
}

export class UpdateAddressDto {
  @ApiProperty({
    description: 'Address label (e.g., Home, Office)',
    example: 'Office',
    maxLength: 50,
    required: false,
  })
  @IsString()
  @MaxLength(50)
  @IsOptional()
  label?: string;

  @ApiProperty({
    description: 'Full street address',
    example: '456 Business Avenue, Mogadishu, Somalia',
    maxLength: 500,
    required: false,
  })
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  @IsOptional()
  fullAddress?: string;

  @ApiProperty({
    description: 'Phone number (accepts both Somali and international formats)',
    example: '+252612345678',
    required: false,
  })
  @IsString()
  @MinLength(7)
  @MaxLength(20)
  @Matches(/^\+?[0-9\s-]{7,20}$/, {
    message: 'Phone number must be a valid phone number',
  })
  @IsOptional()
  phoneNumber?: string;

  @ApiProperty({
    description: 'Set as default address',
    example: false,
    required: false,
  })
  @IsBoolean()
  @IsOptional()
  isDefault?: boolean;
}
