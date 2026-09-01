// src/chat/chat.controller.ts
import {
  Controller,
  Get,
  Put,
  Post,
  Param,
  Query,
  UseGuards,
  Request,
  Body,
  HttpCode,
  HttpStatus,
  Delete,
  DefaultValuePipe,
  ParseIntPipe,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  ForbiddenException,
  Inject,
  ParseUUIDPipe,
  Logger,
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiBody,
  ApiResponse,
  ApiConsumes,
} from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { Redis } from '@upstash/redis';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ChatService } from './chat.service';
import { ChatGateway } from './chat.gateway';
import { SupabaseService } from 'src/supabase/supabase.service';
import { LogSanitizer } from '../common/utils/log-sanitizer.util';

interface RequestUser {
  userId?: string;
  sub?: string;
  id?: string;
}

interface AuthenticatedRequest {
  user: RequestUser;
}

@ApiTags('Chat')
@Controller('chat')
@UseGuards(JwtAuthGuard, ThrottlerGuard)
@ApiBearerAuth('JWT-auth')
export class ChatController {
  private readonly logger = new Logger(ChatController.name);
  private readonly isProduction: boolean;

  constructor(
    private readonly chatService: ChatService,
    private readonly chatGateway: ChatGateway,
    private readonly supabaseService: SupabaseService,
    @Inject('REDIS_CLIENT') private readonly redis: Redis,
  ) {
    this.isProduction = process.env.NODE_ENV === 'production';
  }

  private getUserId(req: AuthenticatedRequest): string {
    const userId = String(req.user.userId || req.user.sub || req.user.id);
    if (!userId || userId === 'undefined') {
      throw new ForbiddenException('Invalid user ID');
    }
    return userId;
  }

  private async getUserOrThrow(userId: string) {
    const user = await this.chatService.getUserById(userId);
    if (!user) {
      throw new BadRequestException('User not found');
    }
    return user;
  }

  private async isSuperAdmin(userId: string): Promise<boolean> {
    const user = await this.getUserOrThrow(userId);
    return Boolean(user.isSuperAdmin);
  }

  private async isAdmin(userId: string): Promise<boolean> {
    const user = await this.getUserOrThrow(userId);
    return Boolean(user.isAdmin || user.isSuperAdmin);
  }

  // ==========================================
  // SUPER ADMIN - ALL CONVERSATIONS
  // ==========================================

  @Get('admin/all-conversations')
  @ApiOperation({ summary: 'Get ALL conversations (Super Admin only)' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'search', required: false })
  async getAllConversations(
    @Request() req: AuthenticatedRequest,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('search') search?: string,
  ) {
    const userId = this.getUserId(req);
    const isSuperAdmin = await this.isSuperAdmin(userId);
    if (!isSuperAdmin) {
      throw new ForbiddenException(
        'Only super admins can access this endpoint',
      );
    }
    return this.chatService.getAllConversationsForSuperAdmin(
      userId,
      page,
      Math.min(limit, 50),
      search,
    );
  }

  @Get('admin/:adminId/users')
  @ApiOperation({
    summary: 'Get all users a specific admin has conversations with',
  })
  @ApiParam({ name: 'adminId', description: 'Admin user ID' })
  @ApiQuery({ name: 'search', required: false })
  async getAdminUsers(
    @Request() req: AuthenticatedRequest,
    @Param('adminId', ParseUUIDPipe) adminId: string,
    @Query('search') search?: string,
  ) {
    const userId = this.getUserId(req);
    const isSuperAdmin = await this.isSuperAdmin(userId);
    if (!isSuperAdmin) {
      throw new ForbiddenException(
        'Only super admins can access this endpoint',
      );
    }
    return this.chatService.getUsersForAdmin(adminId, search);
  }

  @Get('admin/conversation/:conversationId/messages')
  @ApiOperation({
    summary: 'Get messages from any conversation (Super Admin only)',
  })
  @ApiParam({ name: 'conversationId', description: 'Conversation ID' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getConversationMessages(
    @Request() req: AuthenticatedRequest,
    @Param('conversationId', ParseUUIDPipe) conversationId: string,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number,
  ) {
    const userId = this.getUserId(req);
    const isSuperAdmin = await this.isSuperAdmin(userId);
    if (!isSuperAdmin) {
      throw new ForbiddenException(
        'Only super admins can access this endpoint',
      );
    }
    return this.chatService.getConversationMessages(
      conversationId,
      Math.min(limit, 100),
    );
  }

  // ==========================================
  // USER SEARCH
  // ==========================================

  @Get('users/search')
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  @ApiOperation({ summary: 'Search users by name, phone, or email' })
  @ApiQuery({ name: 'q', required: true })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'offset', required: false, type: Number })
  @ApiQuery({ name: 'role', required: false, enum: ['user', 'admin'] })
  @ApiQuery({ name: 'isOnline', required: false, type: Boolean })
  async searchUsers(
    @Query('q') query: string,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('offset', new DefaultValuePipe(0), ParseIntPipe) offset: number,
    @Query('role') role?: 'user' | 'admin',
    @Query('isOnline') isOnline?: string,
  ) {
    if (!query || query.trim().length < 2) {
      throw new BadRequestException(
        'Search query must be at least 2 characters',
      );
    }

    return this.chatService.searchUsers(query.trim(), {
      limit: Math.min(limit, 100),
      offset,
      role,
      isOnline:
        isOnline === 'true' ? true : isOnline === 'false' ? false : undefined,
    });
  }

  @Get('users/chat-search')
  @ApiOperation({ summary: 'Search users for chat' })
  @ApiQuery({ name: 'q', required: true })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async searchChatUsers(
    @Request() req: AuthenticatedRequest,
    @Query('q') query: string,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    if (!query || query.trim().length < 2) {
      throw new BadRequestException(
        'Search query must be at least 2 characters',
      );
    }

    return this.chatService.searchChatUsers(
      this.getUserId(req),
      query.trim(),
      Math.min(limit, 50),
    );
  }

  // ==========================================
  // ADMIN USERS
  // ==========================================

  @Get('admins')
  @ApiOperation({ summary: 'Get available admin users for chat' })
  async getAvailableAdmins() {
    return this.chatService.getAvailableAdmins();
  }

  @Get('admins/chat')
  @ApiOperation({ summary: 'Get admin/super admin users available for chat' })
  async getAdminUsersForChat(@Request() req: AuthenticatedRequest) {
    return this.chatService.getAdminUsersForChat(this.getUserId(req));
  }

  // ==========================================
  // CONVERSATIONS
  // ==========================================

  @Post('conversations')
  @HttpCode(HttpStatus.CREATED)
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiOperation({ summary: 'Create a new conversation' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: { participantId: { type: 'string' } },
      required: ['participantId'],
    },
  })
  async createConversation(
    @Request() req: AuthenticatedRequest,
    @Body('participantId') participantId: string,
  ) {
    if (!participantId || !participantId.trim()) {
      throw new BadRequestException('Participant ID is required');
    }

    return this.chatService.createConversation(
      this.getUserId(req),
      participantId,
    );
  }

  @Get('conversations')
  @ApiOperation({ summary: 'Get all conversations for current user' })
  async getConversations(@Request() req: AuthenticatedRequest) {
    const userId = this.getUserId(req);
    const user = await this.chatService.getUserById(userId);
    return user?.isAdmin || user?.isSuperAdmin
      ? this.chatService.getAdminConversations(userId)
      : this.chatService.getUserConversations(userId);
  }

  // ==========================================
  // MESSAGES
  // ==========================================

  @Get('messages/:partnerId')
  @ApiOperation({ summary: 'Get messages with a specific user' })
  @ApiParam({ name: 'partnerId' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'before', required: false, type: String })
  async getMessages(
    @Request() req: AuthenticatedRequest,
    @Param('partnerId', ParseUUIDPipe) partnerId: string,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number,
    @Query('before') before?: string,
  ) {
    return this.chatService.getMessages(
      this.getUserId(req),
      partnerId,
      Math.min(limit, 100),
      before ? new Date(before) : undefined,
    );
  }

  @Put('messages/:partnerId/read')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Mark all messages from a partner as read' })
  async markAsRead(
    @Request() req: AuthenticatedRequest,
    @Param('partnerId', ParseUUIDPipe) partnerId: string,
  ) {
    return this.chatService.markAsRead(this.getUserId(req), partnerId);
  }

  @Get('messages/unread/count')
  @ApiOperation({ summary: 'Get total unread message count' })
  async getUnreadCount(@Request() req: AuthenticatedRequest) {
    return this.chatService.getUnreadCount(this.getUserId(req));
  }

  // ==========================================
  // DEVICE TOKENS
  // ==========================================

  @Post('device-token')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @ApiOperation({ summary: 'Register device token for push notifications' })
  async registerDeviceToken(
    @Request() req: AuthenticatedRequest,
    @Body() body: { token: string; platform: string },
  ) {
    if (!body.token || !body.token.trim()) {
      throw new BadRequestException('Device token is required');
    }

    // Safe logging - mask token
    if (!this.isProduction) {
      this.logger.log(
        `Registering device token: ${LogSanitizer.maskValue(body.token)}`,
      );
    }

    await this.chatService.registerDeviceToken(
      this.getUserId(req),
      body.token,
      body.platform || 'unknown',
    );
    return { success: true };
  }

  @Delete('device-token')
  @ApiOperation({ summary: 'Unregister device token' })
  async unregisterDeviceToken(
    @Request() req: AuthenticatedRequest,
    @Body() body: { token: string },
  ) {
    if (!body.token || !body.token.trim()) {
      throw new BadRequestException('Device token is required');
    }

    await this.chatService.unregisterDeviceToken(
      this.getUserId(req),
      body.token,
    );
    return { success: true };
  }

  // ==========================================
  // USER STATUS
  // ==========================================

  @Get('users/:userId/status')
  @ApiOperation({ summary: 'Check if a user is online and get basic info' })
  async getUserStatus(@Param('userId', ParseUUIDPipe) userId: string) {
    const [isOnline, user] = await Promise.all([
      this.chatGateway.isUserOnline(userId),
      this.chatService.getUserById(userId),
    ]);

    return {
      userId,
      isOnline,
      lastSeen: isOnline ? null : user?.lastSeen,
      name: user?.name || null,
      phoneNumber: user?.phoneNumber
        ? LogSanitizer.maskPhoneNumber(user.phoneNumber)
        : null,
      profileImage: user?.profileImage || null,
    };
  }

  // ==========================================
  // SEARCH CONVERSATIONS
  // ==========================================

  @Get('search')
  @ApiOperation({ summary: 'Search conversations' })
  @ApiQuery({ name: 'q', required: true })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async searchConversations(
    @Request() req: AuthenticatedRequest,
    @Query('q') query: string,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    if (!query || query.trim().length < 2) return [];
    return this.chatService.searchConversations(
      this.getUserId(req),
      query.trim(),
      Math.min(limit, 50),
    );
  }

  // ==========================================
  // MEDIA UPLOAD
  // ==========================================

  @Post('upload-media')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @ApiOperation({ summary: 'Upload chat media to Supabase' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async uploadChatMedia(@UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('No file uploaded');

    // Validate file type
    const allowedTypes = [
      'image/jpeg',
      'image/png',
      'image/jpg',
      'image/webp',
      'image/gif',
    ];
    if (!allowedTypes.includes(file.mimetype)) {
      throw new BadRequestException(
        'Invalid file type. Only images are allowed.',
      );
    }

    const result = await this.supabaseService.uploadFile(file, 'chat_images');
    return {
      success: true,
      url: result.secure_url,
      public_id: result.public_id,
    };
  }
}
