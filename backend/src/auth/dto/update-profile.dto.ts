import { IsString, IsOptional, IsEmail, IsUUID } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateProfileDto {
  @ApiPropertyOptional({ description: 'User name' })
  @IsString()
  @IsOptional()
  name?: string;

  // ✅ ADD THIS: Allow email to be sent from the frontend
  @ApiPropertyOptional({ description: 'User email' })
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiPropertyOptional({ description: 'Market ID' })
  @IsUUID()
  @IsOptional()
  marketId?: string;
}
