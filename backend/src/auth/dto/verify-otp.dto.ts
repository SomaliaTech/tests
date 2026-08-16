import { IsString, Matches, Length } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class VerifyOtpDto {
  @ApiProperty({
    description: 'Somali phone number (supports multiple formats)',
    example: '+252612345678',
  })
  @IsString()
  @Matches(/^(\+?252|0)?(61|63|68|90)\d{7}$/, {
    message: 'Phone number must be a valid Somali number',
  })
  phoneNumber: string;

  @ApiProperty({
    description: '6-digit OTP code',
    example: '123456',
  })
  @IsString()
  @Length(6, 6, { message: 'OTP code must be exactly 6 digits' })
  otpCode: string;
}
