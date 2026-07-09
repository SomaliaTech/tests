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
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ChatService } from './chat.service';
import { ChatGateway } from './chat.gateway';
import { SupabaseService } from 'src/supabase/supabase.service';

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
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
export class ChatController {
  constructor(
    private readonly chatService: ChatService,
    private readonly chatGateway: ChatGateway,
    private readonly supabaseService: SupabaseService,
  ) {}

  private getUserId(req: AuthenticatedRequest): string {
    return String(req.user.userId || req.user.sub || req.user.id);
  }

  // ==========================================
  // USER SEARCH
  // ==========================================

  @Get('users/search')
  @ApiOperation({ summary: 'Search users by name, phone, or email' })
  @ApiQuery({ name: 'q', required: true, description: 'Search query' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'offset', required: false, type: Number })
  @ApiQuery({
    name: 'role',
    required: false,
    enum: ['user', 'admin'],
    description: 'Filter by role',
  })
  @ApiQuery({
    name: 'isOnline',
    required: false,
    type: Boolean,
    description: 'Filter by online status',
  })
  @ApiResponse({ status: 200, description: 'Search results with pagination' })
  async searchUsers(
    @Query('q') query: string,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
    @Query('offset', new DefaultValuePipe(0), ParseIntPipe) offset: number = 0,
    @Query('role') role?: 'user' | 'admin',
    @Query('isOnline') isOnline?: string,
  ) {
    return this.chatService.searchUsers(query, {
      limit: Math.min(limit, 100),
      offset,
      role,
      isOnline:
        isOnline === 'true' ? true : isOnline === 'false' ? false : undefined,
    });
  }

  @Get('users/chat-search')
  @ApiOperation({ summary: 'Search users for chat (excludes current user)' })
  @ApiQuery({ name: 'q', required: true, description: 'Search query' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'List of users available for chat' })
  async searchChatUsers(
    @Request() req: AuthenticatedRequest,
    @Query('q') query: string,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
  ) {
    const userId = this.getUserId(req);
    return this.chatService.searchChatUsers(userId, query, Math.min(limit, 50));
  }

  // ==========================================
  // ADMIN USERS
  // ==========================================

  @Get('admins')
  @ApiOperation({ summary: 'Get available admin users for chat' })
  @ApiResponse({ status: 200, description: 'List of available admins' })
  async getAvailableAdmins() {
    return this.chatService.getAvailableAdmins();
  }

  @Get('admins/chat')
  @ApiOperation({ summary: 'Get admin/super admin users available for chat' })
  @ApiResponse({
    status: 200,
    description: 'List of available admin users for chat',
  })
  async getAdminUsersForChat(@Request() req: AuthenticatedRequest) {
    const userId = this.getUserId(req);
    return this.chatService.getAdminUsersForChat(userId);
  }

  // ==========================================
  // CONVERSATIONS
  // ==========================================

  @Post('conversations')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new conversation' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        participantId: {
          type: 'string',
          description: 'ID of the user to chat with',
        },
      },
      required: ['participantId'],
    },
  })
  async createConversation(
    @Request() req: AuthenticatedRequest,
    @Body('participantId') participantId: string,
  ) {
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
  @ApiParam({ name: 'partnerId', description: 'Partner user ID' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'before', required: false, type: String })
  async getMessages(
    @Request() req: AuthenticatedRequest,
    @Param('partnerId') partnerId: string,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number = 50,
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
    @Param('partnerId') partnerId: string,
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
  @ApiOperation({ summary: 'Register device token for push notifications' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        token: { type: 'string' },
        platform: { type: 'string', enum: ['ios', 'android', 'web'] },
      },
    },
  })
  async registerDeviceToken(
    @Request() req: AuthenticatedRequest,
    @Body() body: { token: string; platform: string },
  ) {
    const userId = this.getUserId(req);
    await this.chatService.registerDeviceToken(
      userId,
      body.token,
      body.platform,
    );
    return { success: true };
  }

  @Delete('device-token')
  @ApiOperation({ summary: 'Unregister device token' })
  @ApiBody({
    schema: { type: 'object', properties: { token: { type: 'string' } } },
  })
  async unregisterDeviceToken(
    @Request() req: AuthenticatedRequest,
    @Body() body: { token: string },
  ) {
    const userId = this.getUserId(req);
    await this.chatService.unregisterDeviceToken(userId, body.token);
    return { success: true };
  }

  // ==========================================
  // USER STATUS
  // ==========================================

  @Get('users/:userId/status')
  @ApiOperation({ summary: 'Check if a user is online' })
  async getUserStatus(@Param('userId') userId: string) {
    const [isOnline, user] = await Promise.all([
      this.chatGateway.isUserOnline(userId),
      this.chatService.getUserById(userId),
    ]);
    return { userId, isOnline, lastSeen: isOnline ? null : user?.lastSeen };
  }

  // ==========================================
  // SEARCH CONVERSATIONS
  // ==========================================

  @Get('search')
  @ApiOperation({ summary: 'Search conversations by name, phone, or message' })
  @ApiQuery({
    name: 'q',
    required: true,
    description: 'Search query (min 2 characters)',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    description: 'Maximum results to return (default: 20)',
  })
  @ApiResponse({ status: 200, description: 'List of matching conversations' })
  async searchConversations(
    @Request() req: AuthenticatedRequest,
    @Query('q') query: string,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
  ) {
    if (!query || query.trim().length < 2) return [];
    return this.chatService.searchConversations(
      this.getUserId(req),
      query.trim(),
      Math.min(limit, 50),
    );
  }

  // ==========================================
  // MEDIA UPLOAD (SUPABASE)
  // ==========================================

  @Post('upload-media')
  @ApiOperation({ summary: 'Upload chat media (image/file) to Supabase' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
    }),
  )
  async uploadChatMedia(
    @UploadedFile() file: Express.Multer.File,
    @Request() req: AuthenticatedRequest,
  ) {
    if (!file) {
      throw new BadRequestException('No file uploaded');
    }

    // Upload to Supabase Storage in the 'chat_images' folder
    const result = await this.supabaseService.uploadFile(file, 'chat_images');

    return {
      success: true,
      url: result.secure_url,
      public_id: result.public_id,
    };
  }
}
