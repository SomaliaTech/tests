// dto/notification.dto.ts

import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsBoolean,
  IsUUID,
  IsEnum,
  MaxLength,
  IsDateString,
  IsUrl,
  IsNotEmpty,
} from 'class-validator';
import { NotificationType } from '../notification.entity';
import { Transform } from 'class-transformer';

// ==========================================
// CREATE NOTIFICATION DTO
// ==========================================

export class CreateNotificationDto {
  @ApiProperty({ description: 'User ID' })
  @IsUUID()
  @IsNotEmpty()
  userId: string;

  @ApiProperty({ description: 'Notification type', enum: NotificationType })
  @IsEnum(NotificationType)
  @IsNotEmpty()
  type: NotificationType;

  @ApiProperty({ description: 'Notification title' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  title: string;

  @ApiProperty({ description: 'Notification message' })
  @IsString()
  @IsNotEmpty()
  message: string;

  @ApiPropertyOptional({ description: 'Action button text' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  actionText?: string;

  @ApiPropertyOptional({ description: 'Action link URL' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  actionLink?: string;

  @ApiPropertyOptional({ description: 'Image URL' })
  @IsOptional()
  @IsUrl()
  @MaxLength(500)
  imageUrl?: string;
}

// ==========================================
// UPDATE NOTIFICATION DTO
// ==========================================

export class UpdateNotificationDto {
  @ApiPropertyOptional({
    description: 'Notification type',
    enum: NotificationType,
  })
  @IsOptional()
  @IsEnum(NotificationType)
  type?: NotificationType;

  @ApiPropertyOptional({ description: 'Notification title' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  title?: string;

  @ApiPropertyOptional({ description: 'Notification message' })
  @IsOptional()
  @IsString()
  message?: string;

  @ApiPropertyOptional({ description: 'Is notification read' })
  @IsOptional()
  @IsBoolean()
  isRead?: boolean;

  @ApiPropertyOptional({ description: 'Action button text' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  actionText?: string;

  @ApiPropertyOptional({ description: 'Action link URL' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  actionLink?: string;

  @ApiPropertyOptional({ description: 'Image URL' })
  @IsOptional()
  @IsUrl()
  @MaxLength(500)
  imageUrl?: string;
}

// ==========================================
// BROADCAST NOTIFICATION DTO
// ==========================================

export class BroadcastNotificationDto {
  @ApiProperty({ description: 'Notification title' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  title: string;

  @ApiProperty({ description: 'Notification message' })
  @IsString()
  @IsNotEmpty()
  message: string;

  @ApiPropertyOptional({ description: 'Action button text' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  actionText?: string;

  @ApiPropertyOptional({ description: 'Action link URL' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  actionLink?: string;

  @ApiPropertyOptional({ description: 'Target audience filter' })
  @IsOptional()
  @IsString()
  targetAudience?: string;

  @ApiPropertyOptional({ description: 'Send push notification' })
  @IsOptional()
  @Transform(({ value }) => {
    // Handle both boolean and string values from multipart form
    if (typeof value === 'boolean') return value;
    if (typeof value === 'string') {
      const lower = value.toLowerCase();
      if (lower === 'true') return true;
      if (lower === 'false') return false;
    }
    return value;
  })
  @IsBoolean()
  sendPush?: boolean;

  @ApiPropertyOptional({ description: 'Schedule for later' })
  @IsOptional()
  @IsDateString()
  scheduledAt?: string;

  @ApiPropertyOptional({ description: 'Image URL (auto-uploaded from file)' })
  @IsOptional()
  @IsUrl()
  @MaxLength(500)
  imageUrl?: string;
}

// ==========================================
// NOTIFICATION RESPONSE DTO
// ==========================================

export class NotificationResponseDto {
  @ApiProperty({ description: 'Notification ID' })
  id: string;

  @ApiProperty({ description: 'User ID' })
  userId: string;

  @ApiProperty({ description: 'Notification type', enum: NotificationType })
  type: NotificationType;

  @ApiProperty({ description: 'Notification title' })
  title: string;

  @ApiProperty({ description: 'Notification message' })
  message: string;

  @ApiProperty({ description: 'Is notification read' })
  isRead: boolean;

  @ApiProperty({ description: 'Action button text' })
  actionText?: string;

  @ApiProperty({ description: 'Action link URL' })
  actionLink?: string;

  @ApiProperty({ description: 'Image URL' })
  imageUrl?: string;

  @ApiProperty({ description: 'Created at' })
  createdAt: Date;

  @ApiProperty({ description: 'Updated at' })
  updatedAt?: Date;
}

// ==========================================
// PAGINATION DTO
// ==========================================

export class NotificationPaginationDto {
  @ApiProperty({ description: 'Page number', default: 1 })
  page: number;

  @ApiProperty({ description: 'Items per page', default: 20 })
  limit: number;

  @ApiProperty({ description: 'Total items' })
  total: number;

  @ApiProperty({ description: 'Total pages' })
  totalPages: number;
}

export class NotificationListResponseDto {
  @ApiProperty({ type: [NotificationResponseDto] })
  items: NotificationResponseDto[];

  @ApiProperty({ type: NotificationPaginationDto })
  pagination: NotificationPaginationDto;
}

// ==========================================
// BULK CREATE NOTIFICATION DTO
// ==========================================

export class BulkCreateNotificationDto {
  @ApiProperty({ description: 'User IDs', type: [String] })
  @IsUUID('4', { each: true })
  @IsNotEmpty()
  userIds: string[];

  @ApiProperty({ description: 'Notification type', enum: NotificationType })
  @IsEnum(NotificationType)
  @IsNotEmpty()
  type: NotificationType;

  @ApiProperty({ description: 'Notification title' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  title: string;

  @ApiProperty({ description: 'Notification message' })
  @IsString()
  @IsNotEmpty()
  message: string;

  @ApiPropertyOptional({ description: 'Action button text' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  actionText?: string;

  @ApiPropertyOptional({ description: 'Action link URL' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  actionLink?: string;

  @ApiPropertyOptional({ description: 'Image URL' })
  @IsOptional()
  @IsUrl()
  @MaxLength(500)
  imageUrl?: string;
}

// ==========================================
// UNREAD COUNT RESPONSE DTO
// ==========================================

export class UnreadCountResponseDto {
  @ApiProperty({ description: 'Number of unread notifications' })
  unreadCount: number;
}

// ==========================================
// DELETE NOTIFICATION RESPONSE DTO
// ==========================================

export class DeleteNotificationResponseDto {
  @ApiProperty({ description: 'Success message' })
  message: string;
}

// ==========================================
// MARK READ RESPONSE DTO
// ==========================================

export class MarkReadResponseDto {
  @ApiProperty({ description: 'Success message' })
  message: string;
}
