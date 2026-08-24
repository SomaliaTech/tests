import { IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class FacebookAuthDto {
  @ApiProperty({ description: 'Facebook access token' })
  @IsString()
  accessToken: string;
}
