import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiParam,
  ApiBody,
} from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard'; // ✅ Import AdminGuard
import {
  CreateNotificationDto,
  UpdateNotificationDto,
} from './dto/notification.dto';

@ApiTags('notifications')
@Controller('notifications')
@UseGuards(JwtAuthGuard) // ✅ All routes require JWT authentication
@ApiBearerAuth('JWT-auth')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  @ApiOperation({
    summary: 'Get user notifications',
    description: 'Returns all notifications for the authenticated user.',
  })
  @ApiResponse({
    status: 200,
    description: 'Notifications retrieved successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async getUserNotifications(@Request() req) {
    return this.notificationsService.getUserNotifications(req.user.userId);
  }

  @Get('unread/count')
  @ApiOperation({
    summary: 'Get unread notification count',
    description:
      'Returns the count of unread notifications for the authenticated user.',
  })
  @ApiResponse({
    status: 200,
    description: 'Unread count retrieved',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async getUnreadCount(@Request() req) {
    return this.notificationsService.getUnreadCount(req.user.userId);
  }

  @Put(':id/read')
  @ApiOperation({
    summary: 'Mark notification as read',
    description: 'Marks a specific notification as read.',
  })
  @ApiParam({
    name: 'id',
    description: 'Notification UUID',
  })
  @ApiResponse({
    status: 200,
    description: 'Notification marked as read',
  })
  @ApiResponse({
    status: 404,
    description: 'Notification not found',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async markAsRead(@Request() req, @Param('id') id: string) {
    return this.notificationsService.markAsRead(id, req.user.userId);
  }

  @Put('read-all')
  @ApiOperation({
    summary: 'Mark all as read',
    description: 'Marks all notifications as read for the authenticated user.',
  })
  @ApiResponse({
    status: 200,
    description: 'All notifications marked as read',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async markAllAsRead(@Request() req) {
    return this.notificationsService.markAllAsRead(req.user.userId);
  }

  @Delete(':id')
  @ApiOperation({
    summary: 'Delete notification',
    description: 'Deletes a specific notification.',
  })
  @ApiParam({
    name: 'id',
    description: 'Notification UUID',
  })
  @ApiResponse({
    status: 200,
    description: 'Notification deleted successfully',
  })
  @ApiResponse({
    status: 404,
    description: 'Notification not found',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async deleteNotification(@Request() req, @Param('id') id: string) {
    return this.notificationsService.deleteNotification(id, req.user.userId);
  }

  @Delete()
  @ApiOperation({
    summary: 'Clear all notifications',
    description: 'Deletes all notifications for the authenticated user.',
  })
  @ApiResponse({
    status: 200,
    description: 'All notifications cleared',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async clearAllNotifications(@Request() req) {
    return this.notificationsService.clearAllNotifications(req.user.userId);
  }

  // ==========================================
  // ADMIN ENDPOINTS
  // ==========================================

  @Post()
  @UseGuards(AdminGuard) // ✅ Only admins can create notifications
  @ApiOperation({
    summary: 'Create notification (Admin)',
    description:
      'Creates a new notification for a user. Requires admin privileges.',
  })
  @ApiBody({ type: CreateNotificationDto })
  @ApiResponse({
    status: 201,
    description: 'Notification created successfully',
  })
  @ApiResponse({
    status: 400,
    description: 'Invalid notification data',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Admin access required',
  })
  async createNotification(
    @Body() createNotificationDto: CreateNotificationDto,
  ) {
    return this.notificationsService.create(createNotificationDto);
  }

  @Put(':id')
  @UseGuards(AdminGuard) // ✅ Only admins can update notifications
  @ApiOperation({
    summary: 'Update notification (Admin)',
    description: 'Updates a specific notification. Requires admin privileges.',
  })
  @ApiParam({
    name: 'id',
    description: 'Notification UUID',
  })
  @ApiBody({ type: UpdateNotificationDto })
  @ApiResponse({
    status: 200,
    description: 'Notification updated successfully',
  })
  @ApiResponse({
    status: 404,
    description: 'Notification not found',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Admin access required',
  })
  async updateNotification(
    @Param('id') id: string,
    @Body() updateNotificationDto: UpdateNotificationDto,
  ) {
    return this.notificationsService.updateNotification(
      id,
      updateNotificationDto,
    );
  }
}
