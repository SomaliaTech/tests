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
  // SUPER ADMIN - ALL CONVERSATIONS
  // ==========================================

  @Get('admin/all-conversations')
  @ApiOperation({ summary: 'Get ALL conversations (Super Admin only)' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'search', required: false })
  async getAllConversations(
    @Request() req: AuthenticatedRequest,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
    @Query('search') search?: string,
  ) {
    const userId = this.getUserId(req);
    const user = await this.chatService.getUserById(userId);
    if (!user?.isSuperAdmin) {
      throw new ForbiddenException(
        'Only super admins can access this endpoint',
      );
    }
    return this.chatService.getAllConversationsForSuperAdmin(
      userId,
      page,
      limit,
      search,
    );
  }
  @Get('admin/:adminId/users')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({
    summary: 'Get all users a specific admin has conversations with',
  })
  @ApiParam({ name: 'adminId', description: 'Admin user ID' })
  @ApiQuery({ name: 'search', required: false })
  async getAdminUsers(
    @Request() req: AuthenticatedRequest,
    @Param('adminId') adminId: string,
    @Query('search') search?: string,
  ) {
    const userId = this.getUserId(req);
    const user = await this.chatService.getUserById(userId);
    if (!user?.isSuperAdmin) {
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
    @Param('conversationId') conversationId: string,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit: number = 50,
  ) {
    const userId = this.getUserId(req);
    const user = await this.chatService.getUserById(userId);
    if (!user?.isSuperAdmin) {
      throw new ForbiddenException(
        'Only super admins can access this endpoint',
      );
    }
    return this.chatService.getConversationMessages(conversationId, limit);
  }

  // ==========================================
  // USER SEARCH
  // ==========================================

  @Get('users/search')
  @ApiOperation({ summary: 'Search users by name, phone, or email' })
  @ApiQuery({ name: 'q', required: true })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'offset', required: false, type: Number })
  @ApiQuery({ name: 'role', required: false, enum: ['user', 'admin'] })
  @ApiQuery({ name: 'isOnline', required: false, type: Boolean })
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
  @ApiOperation({ summary: 'Search users for chat' })
  @ApiQuery({ name: 'q', required: true })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async searchChatUsers(
    @Request() req: AuthenticatedRequest,
    @Query('q') query: string,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
  ) {
    return this.chatService.searchChatUsers(
      this.getUserId(req),
      query,
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
  async registerDeviceToken(
    @Request() req: AuthenticatedRequest,
    @Body() body: { token: string; platform: string },
  ) {
    await this.chatService.registerDeviceToken(
      this.getUserId(req),
      body.token,
      body.platform,
    );
    return { success: true };
  }

  @Delete('device-token')
  @ApiOperation({ summary: 'Unregister device token' })
  async unregisterDeviceToken(
    @Request() req: AuthenticatedRequest,
    @Body() body: { token: string },
  ) {
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
  async getUserStatus(@Param('userId') userId: string) {
    const [isOnline, user] = await Promise.all([
      this.chatGateway.isUserOnline(userId),
      this.chatService.getUserById(userId),
    ]);
    return {
      userId,
      isOnline,
      lastSeen: isOnline ? null : user?.lastSeen,
      name: user?.name || null,
      phoneNumber: user?.phoneNumber || null,
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
  // MEDIA UPLOAD
  // ==========================================

  @Post('upload-media')
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
    const result = await this.supabaseService.uploadFile(file, 'chat_images');
    return {
      success: true,
      url: result.secure_url,
      public_id: result.public_id,
    };
  }
}
