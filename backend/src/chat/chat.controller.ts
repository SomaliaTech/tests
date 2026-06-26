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
} from '@nestjs/common';
import {
  ApiTags,
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiBody,
  ApiResponse,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ChatService } from './chat.service';
import { ChatGateway } from './chat.gateway';

// ✅ Define proper request user interface
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
  ) {}

  // ✅ Properly typed getUserId
  private getUserId(req: AuthenticatedRequest): string {
    return String(req.user.userId || req.user.sub || req.user.id);
  }

  // ✅ ADDED: Search users endpoint
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
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
    @Query('role') role?: 'user' | 'admin',
    @Query('isOnline') isOnline?: string,
  ) {
    return this.chatService.searchUsers(query, {
      limit: limit ? Number(limit) : 20,
      offset: offset ? Number(offset) : 0,
      role,
      isOnline:
        isOnline === 'true' ? true : isOnline === 'false' ? false : undefined,
    });
  }

  // ✅ ADDED: Quick search for chat (excludes current user, respects permissions)
  @Get('users/chat-search')
  @ApiOperation({
    summary:
      'Search users for chat (excludes current user, respects permissions)',
  })
  @ApiQuery({ name: 'q', required: true, description: 'Search query' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({
    status: 200,
    description: 'List of users available for chat',
  })
  async searchChatUsers(
    @Request() req: AuthenticatedRequest,
    @Query('q') query: string,
    @Query('limit') limit?: string,
  ) {
    const userId = this.getUserId(req);
    return this.chatService.searchChatUsers(
      userId,
      query,
      limit ? Number(limit) : 20,
    );
  }

  @Get('admins')
  @ApiOperation({ summary: 'Get available admin users for chat' })
  @ApiResponse({ status: 200, description: 'List of available admins' })
  async getAvailableAdmins() {
    return this.chatService.getAvailableAdmins();
  }

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

  @Post('device-token')
  @ApiOperation({ summary: 'Register device token for push notifications' })
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
  async unregisterDeviceToken(
    @Request() req: AuthenticatedRequest,
    @Body() body: { token: string },
  ) {
    const userId = this.getUserId(req);
    await this.chatService.unregisterDeviceToken(userId, body.token);
    return { success: true };
  }

  @Get('search')
  @ApiOperation({ summary: 'Search conversations by name, phone, or message' })
  @ApiQuery({
    name: 'q',
    required: true,
    description: 'Search query (min 2 characters)',
    example: 'john',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    description: 'Maximum results to return (default: 20)',
    example: 20,
  })
  @ApiResponse({
    status: 200,
    description: 'List of matching conversations',
  })
  async searchConversations(
    @Request() req: AuthenticatedRequest,
    @Query('q') query: string,
    @Query('limit') limit?: string,
  ) {
    if (!query || query.trim().length < 2) {
      return [];
    }

    return this.chatService.searchConversations(
      this.getUserId(req),
      query.trim(),
      limit ? Math.min(Number(limit), 50) : 20,
    );
  }

  @Get('conversations')
  @ApiOperation({ summary: 'Get all conversations for current user' })
  async getConversations(@Request() req: AuthenticatedRequest) {
    const userId = this.getUserId(req);
    const user = await this.chatService.getUserById(userId);

    return user?.isAdmin
      ? this.chatService.getAdminConversations(userId)
      : this.chatService.getUserConversations(userId);
  }

  @Get('messages/:partnerId')
  @ApiOperation({ summary: 'Get messages with a specific user' })
  @ApiParam({ name: 'partnerId', description: 'Partner user ID' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'before', required: false, type: String })
  async getMessages(
    @Request() req: AuthenticatedRequest,
    @Param('partnerId') partnerId: string,
    @Query('limit') limit?: string,
    @Query('before') before?: string,
  ) {
    return this.chatService.getMessages(
      this.getUserId(req),
      partnerId,
      limit ? Number(limit) : 50,
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

  @Get('users/:userId/status')
  @ApiOperation({ summary: 'Check if a user is online' })
  async getUserStatus(@Param('userId') userId: string) {
    const isOnline = this.chatGateway.isUserOnline(userId);
    const user = await this.chatService.getUserById(userId);

    return {
      userId,
      isOnline,
      lastSeen: isOnline ? null : user?.lastSeen,
    };
  }
}
