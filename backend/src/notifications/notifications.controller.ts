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
  Query,
  DefaultValuePipe,
  ParseIntPipe,
  ParseUUIDPipe,
  HttpCode,
  HttpStatus,
  BadRequestException,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiParam,
  ApiBody,
  ApiQuery,
} from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import {
  CreateNotificationDto,
  UpdateNotificationDto,
} from './dto/notification.dto';
import { NotificationType } from './notification.entity';

@ApiTags('notifications')
@Controller('notifications')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  // ==========================================
  // USER ENDPOINTS
  // ==========================================

  @Get()
  @ApiOperation({
    summary: 'Get user notifications',
    description:
      'Returns all notifications for the authenticated user with pagination.',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'type', required: false, enum: NotificationType })
  @ApiQuery({ name: 'isRead', required: false, type: Boolean })
  @ApiResponse({
    status: 200,
    description: 'Notifications retrieved successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized',
  })
  async getUserNotifications(
    @Request() req,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
    @Query('type') type?: NotificationType,
    @Query('isRead') isRead?: string,
  ) {
    const isReadBool =
      isRead === 'true' ? true : isRead === 'false' ? false : undefined;
    return this.notificationsService.getUserNotifications(
      req.user.userId,
      page,
      limit,
      type,
      isReadBool,
    );
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
  async markAsRead(@Request() req, @Param('id', ParseUUIDPipe) id: string) {
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
  async deleteNotification(
    @Request() req,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
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

  @Get('admin/all')
  @UseGuards(AdminGuard)
  @ApiOperation({
    summary: 'Get all notifications (Admin)',
    description:
      'Returns all notifications with pagination. Requires admin privileges.',
  })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({
    name: 'userId',
    required: false,
    description: 'Filter by user ID',
  })
  @ApiQuery({ name: 'type', required: false, enum: NotificationType })
  @ApiResponse({
    status: 200,
    description: 'All notifications retrieved successfully',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - Admin access required',
  })
  async getAllNotificationsAdmin(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
    @Query('userId') userId?: string,
    @Query('type') type?: NotificationType,
  ) {
    return this.notificationsService.getAllNotificationsAdmin(
      page,
      limit,
      userId,
      type,
    );
  }

  @Post()
  @UseGuards(AdminGuard)
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

  @Post('bulk')
  @UseGuards(AdminGuard)
  @ApiOperation({
    summary: 'Bulk create notifications (Admin)',
    description:
      'Creates notifications for multiple users. Requires admin privileges.',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        userIds: {
          type: 'array',
          items: { type: 'string' },
          description: 'Array of user IDs',
        },
        type: { type: 'string', enum: Object.values(NotificationType) },
        title: { type: 'string' },
        message: { type: 'string' },
        actionText: { type: 'string' },
        actionLink: { type: 'string' },
      },
      required: ['userIds', 'type', 'title', 'message'],
    },
  })
  @ApiResponse({
    status: 201,
    description: 'Notifications created successfully',
  })
  async bulkCreateNotifications(
    @Body()
    body: {
      userIds: string[];
      type: NotificationType;
      title: string;
      message: string;
      actionText?: string;
      actionLink?: string;
    },
  ) {
    if (!body.userIds || body.userIds.length === 0) {
      throw new BadRequestException('userIds array is required');
    }
    return this.notificationsService.bulkCreateNotifications(body);
  }

  @Put(':id')
  @UseGuards(AdminGuard)
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
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateNotificationDto: UpdateNotificationDto,
  ) {
    return this.notificationsService.updateNotification(
      id,
      updateNotificationDto,
    );
  }

  @Delete('admin/:id')
  @UseGuards(AdminGuard)
  @ApiOperation({
    summary: 'Delete notification (Admin)',
    description: 'Deletes any notification. Requires admin privileges.',
  })
  @ApiParam({
    name: 'id',
    description: 'Notification UUID',
  })
  @ApiResponse({
    status: 200,
    description: 'Notification deleted successfully',
  })
  async deleteNotificationAdmin(@Param('id', ParseUUIDPipe) id: string) {
    return this.notificationsService.deleteNotificationAdmin(id);
  }
}
