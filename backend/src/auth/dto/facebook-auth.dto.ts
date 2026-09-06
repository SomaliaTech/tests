// src/auth/dto/facebook-auth.dto.ts
import { IsString, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class FacebookAuthDto {
  @ApiProperty({ description: 'Facebook access token' })
  @IsString()
  @IsNotEmpty()
  accessToken: string;
}
