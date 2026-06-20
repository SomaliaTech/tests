import { ApiProperty } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsBoolean,
  IsPhoneNumber,
  MaxLength,
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
  @MaxLength(500)
  fullAddress: string;

  @ApiProperty({
    description: 'Phone number in international format',
    example: '+252612345678',
  })
  @IsString()
  @IsPhoneNumber()
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
  @MaxLength(500)
  @IsOptional()
  fullAddress?: string;

  @ApiProperty({
    description: 'Phone number in international format',
    example: '+252612345678',
    required: false,
  })
  @IsString()
  @IsPhoneNumber()
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
