// src/auth/dto/google-auth.dto.ts
import { IsString, IsNotEmpty, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class GoogleAuthDto {
  @ApiProperty({
    description: 'Google ID Token from Google Sign-In SDK',
    example: 'eyJhbGciOiJSUzI1NiIs...',
  })
  @IsString()
  @IsNotEmpty({ message: 'ID token is required' })
  @MinLength(20, { message: 'Invalid ID token format' })
  idToken: string;

  // ❌ REMOVE THESE - They should come from the VERIFIED token, not from the request!
  // email: string;
  // name: string;
  // photoUrl: string;
}
