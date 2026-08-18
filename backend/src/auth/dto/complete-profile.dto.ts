// complete-profile.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  Length,
  IsUrl,
  IsUUID,
  Matches,
} from 'class-validator';

export class CompleteProfileDto {
  @ApiProperty({
    description: 'User full name',
    example: 'farah jamac',
    minLength: 2,
    maxLength: 255,
  })
  @IsString()
  @Length(2, 255)
  name: string;

  @ApiProperty({
    description: 'Market ID',
    example: '123e4567-e89b-12d3-a456-426614174000',
  })
  @IsUUID()
  @IsString()
  marketId: string;

  @ApiProperty({
    description:
      'Phone number (international format for Google users, Somali format for OTP users)',
    example: '+14155552671',
    required: false,
  })
  @IsString()
  @IsOptional()
  @Matches(/^\+?\d{6,15}$/, {
    message: 'Phone number must be between 6 and 15 digits',
  })
  phoneNumber?: string;

  @ApiProperty({
    description: 'Profile image URL or base64',
    example: 'https://example.com/profile.jpg',
    required: false,
  })
  @IsString()
  @IsOptional()
  profileImage?: string;
}
