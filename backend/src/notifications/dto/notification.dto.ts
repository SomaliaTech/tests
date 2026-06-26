// notification.dto.ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsUUID,
  IsBoolean,
  IsOptional,
  IsEnum,
} from 'class-validator';
import { NotificationType } from '../notification.entity';

export class CreateNotificationDto {
  @ApiProperty({
    description: 'User ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsUUID()
  @IsString()
  userId!: string;

  @ApiProperty({ description: 'Notification type', enum: NotificationType })
  @IsEnum(NotificationType)
  type!: NotificationType;

  @ApiProperty({
    description: 'Notification title',
    example: 'Order Delivered',
  })
  @IsString()
  title!: string;

  @ApiProperty({
    description: 'Notification message',
    example: 'Your order has been delivered',
  })
  @IsString()
  message!: string;

  @ApiPropertyOptional({ description: 'Action text', example: 'View Order' })
  @IsOptional()
  @IsString()
  actionText?: string;

  @ApiPropertyOptional({
    description: 'Action link',
    example: '/orders/123',
  })
  @IsOptional()
  @IsString()
  actionLink?: string;
}

export class UpdateNotificationDto {
  @ApiPropertyOptional({ description: 'Mark as read', example: true })
  @IsOptional()
  @IsBoolean()
  isRead?: boolean;
}
