import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional, IsEmail, Length, IsUrl } from 'class-validator';

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
    description: 'User email address',
    example: 'farah@example.com',
    required: false,
  })
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiProperty({
    description: 'Profile image URL',
    example: 'https://example.com/profile.jpg',
    required: false,
  })
  @IsUrl()
  @IsOptional()
  profileImage?: string;
}
