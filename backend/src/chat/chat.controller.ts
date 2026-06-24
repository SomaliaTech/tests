import {
  Controller,
  Get,
  Param,
  UseGuards,
  Request,
  Put,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ChatService } from './chat.service';

@ApiTags('chat')
@Controller('chat')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get('history/:partnerId')
  async getHistory(@Request() req, @Param('partnerId') partnerId: string) {
    const userId = req.user.userId;
    return this.chatService.getChatHistory(userId, partnerId);
  }

  @Get('conversations')
  async getConversations(@Request() req) {
    const userId = req.user.userId;
    const isAdmin = req.user.isAdmin || false;

    if (isAdmin) {
      return this.chatService.getAdminConversations(userId);
    } else {
      return this.chatService.getUserConversations(userId);
    }
  }

  // ✅ ADD THIS: Mark messages as read
  @Put('mark-read/:partnerId')
  @ApiOperation({ summary: 'Mark all messages from a partner as read' })
  async markAsRead(@Request() req, @Param('partnerId') partnerId: string) {
    const userId = req.user.userId;
    return this.chatService.markAsRead(userId, partnerId);
  }
}
