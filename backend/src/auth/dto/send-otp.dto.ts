import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty } from 'class-validator';

export class SendOtpDto {
  @ApiProperty({
    description: 'Phone number in international format',
    example: '+252612345678',
  })
  @IsString()
  @IsNotEmpty()
  phoneNumber: string;
}
