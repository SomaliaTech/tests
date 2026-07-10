import { ApiProperty } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsBoolean,
  IsNumber,
  MaxLength,
  MinLength,
} from 'class-validator';

export class CreateFaqDto {
  @ApiProperty({ description: 'FAQ question', maxLength: 500 })
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  question: string;

  @ApiProperty({ description: 'FAQ answer', maxLength: 5000 })
  @IsString()
  @MinLength(5)
  @MaxLength(5000)
  answer: string;

  @ApiProperty({ description: 'FAQ category', required: false, maxLength: 100 })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  category?: string;

  @ApiProperty({ description: 'Display order', default: 0 })
  @IsOptional()
  @IsNumber()
  order?: number;

  @ApiProperty({ description: 'Is FAQ active', default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
