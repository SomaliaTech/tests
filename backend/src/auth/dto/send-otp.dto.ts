// send-otp.dto.ts
import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, Matches } from 'class-validator';

export class SendOtpDto {
  @ApiProperty({
    description: 'Phone number - can be local or international format',
    example: '612345678',
    examples: ['612345678', '0612345678', '+252612345678'],
  })
  @IsString()
  @IsNotEmpty()
  @Matches(/^(\+252)?[0]?[0-9]{9}$/, {
    message: 'Phone number must be a valid Somali number (9 digits)',
  })
  phoneNumber: string;
}
