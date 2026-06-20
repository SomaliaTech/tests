import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsOptional, MaxLength } from 'class-validator';

export class CreateCategoryDto {
  @ApiProperty({
    description: 'Category name',
    example: 'Electronics',
    maxLength: 255,
  })
  @IsString()
  @MaxLength(255)
  name: string;

  @ApiProperty({
    description: 'Category slug (URL-friendly identifier)',
    example: 'electronics',
    maxLength: 255,
  })
  @IsString()
  @MaxLength(255)
  slug: string;

  @ApiProperty({
    description: 'Category description',
    example: 'Electronic devices and gadgets',
    required: false,
  })
  @IsString()
  @IsOptional()
  description?: string;
}
