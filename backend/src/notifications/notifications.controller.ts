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
  BadRequestException,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiParam,
  ApiBody,
  ApiQuery,
  ApiConsumes,
} from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { SuperAdminGuard } from '../auth/guards/super-admin.guard'; // Optional: if you want strict super admin for broadcast
import { SupabaseService } from '../supabase/supabase.service'; // Adjust import to match your project
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
  constructor(
    private readonly notificationsService: NotificationsService,
    private readonly supabaseService: SupabaseService, // Inject storage service
  ) {}

  // ==========================================
  // BROADCAST (With Image Support)
  // ==========================================
  @Post('broadcast')
  @UseGuards(SuperAdminGuard) // Or AdminGuard depending on your security policy
  @UseInterceptors(FileInterceptor('image'))
  @ApiConsumes('multipart/form-data', 'application/json')
  @ApiOperation({
    summary: 'Broadcast notification to all users with optional image',
  })
  async broadcastNotification(
    @Request() req,
    @Body() body: any,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    // Handle case where data might be sent as a JSON string inside multipart form
    let dto = body;
    if (typeof body === 'string') {
      try {
        dto = JSON.parse(body);
      } catch {
        dto = {};
      }
    }

    let imageUrl: string | undefined = undefined;

    // ✅ Upload Image if present
    if (file) {
      try {
        // ✅ FIX 1: Pass only the file object (1 argument).
        // If your service actually expects a base64 string, use the commented code below instead.
        const uploadResult = await this.supabaseService.uploadFile(file);

        // const base64Image = `data:${file.mimetype};base64,${file.buffer.toString('base64')}`;
        // const uploadResult = await this.supabaseService.uploadImage(base64Image);

        // ✅ FIX 2: Use 'secure_url' instead of 'publicUrl' based on the TypeScript error
        imageUrl = uploadResult.secure_url;
      } catch (error) {
        console.error('Image upload error:', error);
        throw new BadRequestException('Failed to upload broadcast image');
      }
    }

    return this.notificationsService.broadcastToAllUsers({
      title: dto.title,
      message: dto.message,
      actionText: dto.actionText,
      actionLink: dto.actionLink,
      imageUrl, // ✅ Pass URL to service
      targetAudience: dto.targetAudience || 'all_users',
      sendPush: dto.sendPush === 'true' || dto.sendPush === true,
      scheduledAt: dto.scheduledAt ? new Date(dto.scheduledAt) : undefined,
    });
  }
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
  @ApiResponse({ status: 401, description: 'Unauthorized' })
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
  @ApiOperation({ summary: 'Get unread notification count' })
  @ApiResponse({ status: 200, description: 'Unread count retrieved' })
  async getUnreadCount(@Request() req) {
    return this.notificationsService.getUnreadCount(req.user.userId);
  }

  @Put(':id/read')
  @ApiOperation({ summary: 'Mark notification as read' })
  @ApiParam({ name: 'id', description: 'Notification UUID' })
  @ApiResponse({ status: 200, description: 'Notification marked as read' })
  async markAsRead(@Request() req, @Param('id', ParseUUIDPipe) id: string) {
    return this.notificationsService.markAsRead(id, req.user.userId);
  }

  @Put('read-all')
  @ApiOperation({ summary: 'Mark all as read' })
  @ApiResponse({ status: 200, description: 'All notifications marked as read' })
  async markAllAsRead(@Request() req) {
    return this.notificationsService.markAllAsRead(req.user.userId);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete notification' })
  @ApiParam({ name: 'id', description: 'Notification UUID' })
  @ApiResponse({
    status: 200,
    description: 'Notification deleted successfully',
  })
  async deleteNotification(
    @Request() req,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.notificationsService.deleteNotification(id, req.user.userId);
  }

  @Delete()
  @ApiOperation({ summary: 'Clear all notifications' })
  @ApiResponse({ status: 200, description: 'All notifications cleared' })
  async clearAllNotifications(@Request() req) {
    return this.notificationsService.clearAllNotifications(req.user.userId);
  }

  // ==========================================
  // ADMIN ENDPOINTS
  // ==========================================

  @Get('admin/all')
  @UseGuards(AdminGuard)
  @ApiOperation({ summary: 'Get all notifications (Admin)' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'userId', required: false })
  @ApiQuery({ name: 'type', required: false, enum: NotificationType })
  @ApiResponse({
    status: 200,
    description: 'All notifications retrieved successfully',
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
  @ApiOperation({ summary: 'Create notification (Admin)' })
  @ApiBody({ type: CreateNotificationDto })
  @ApiResponse({
    status: 201,
    description: 'Notification created successfully',
  })
  async createNotification(
    @Body() createNotificationDto: CreateNotificationDto,
  ) {
    return this.notificationsService.create(createNotificationDto);
  }

  @Post('bulk')
  @UseGuards(AdminGuard)
  @ApiOperation({ summary: 'Bulk create notifications (Admin)' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        userIds: { type: 'array', items: { type: 'string' } },
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
  @ApiOperation({ summary: 'Update notification (Admin)' })
  @ApiParam({ name: 'id', description: 'Notification UUID' })
  @ApiBody({ type: UpdateNotificationDto })
  @ApiResponse({
    status: 200,
    description: 'Notification updated successfully',
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
  @ApiOperation({ summary: 'Delete notification (Admin)' })
  @ApiParam({ name: 'id', description: 'Notification UUID' })
  @ApiResponse({
    status: 200,
    description: 'Notification deleted successfully',
  })
  async deleteNotificationAdmin(@Param('id', ParseUUIDPipe) id: string) {
    return this.notificationsService.deleteNotificationAdmin(id);
  }
}
