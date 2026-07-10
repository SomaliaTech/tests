import { ApiProperty } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsBoolean,
  IsUUID,
  IsEnum,
  MaxLength,
} from 'class-validator';
import { NotificationType } from '../notification.entity';

export class CreateNotificationDto {
  @ApiProperty({ description: 'User ID' })
  @IsUUID()
  userId: string;

  @ApiProperty({ description: 'Notification type', enum: NotificationType })
  @IsEnum(NotificationType)
  type: NotificationType;

  @ApiProperty({ description: 'Notification title', maxLength: 255 })
  @IsString()
  @MaxLength(255)
  title: string;

  @ApiProperty({ description: 'Notification message' })
  @IsString()
  message: string;

  @ApiProperty({ description: 'Action button text', required: false })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  actionText?: string;

  @ApiProperty({ description: 'Action link URL', required: false })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  actionLink?: string;
}

export class UpdateNotificationDto {
  @ApiProperty({
    description: 'Notification type',
    enum: NotificationType,
    required: false,
  })
  @IsOptional()
  @IsEnum(NotificationType)
  type?: NotificationType;

  @ApiProperty({ description: 'Notification title', required: false })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  title?: string;

  @ApiProperty({ description: 'Notification message', required: false })
  @IsOptional()
  @IsString()
  message?: string;

  @ApiProperty({ description: 'Is notification read', required: false })
  @IsOptional()
  @IsBoolean()
  isRead?: boolean;

  @ApiProperty({ description: 'Action button text', required: false })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  actionText?: string;

  @ApiProperty({ description: 'Action link URL', required: false })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  actionLink?: string;
}
