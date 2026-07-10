// complete-profile.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional, Length, IsUrl, IsUUID } from 'class-validator';

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

  // ✅ EMAIL COMPLETELY REMOVED

  @ApiProperty({
    description: 'Market ID',
    example: '123e4567-e89b-12d3-a456-426614174000',
  })
  @IsUUID()
  @IsString()
  marketId: string;

  @ApiProperty({
    description: 'Profile image URL',
    example: 'https://example.com/profile.jpg',
    required: false,
  })
  @IsUrl()
  @IsOptional()
  profileImage?: string;
}
