import { Logger } from '@nestjs/common';
import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayInit,
  OnGatewayConnection,
  OnGatewayDisconnect,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ChatService } from './chat.service';
import { FirebaseService } from '../firebase/firebase.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateNotificationDto } from '../notifications/dto/notification.dto';
import { NotificationType } from 'src/notifications/notification.entity';

interface SocketMeta {
  userId: string;
  isAdmin: boolean;
}

interface SendMessageData {
  receiverId: string;
  content?: string;
  type?: 'text' | 'image' | 'file';
  mediaUrl?: string;
}

interface MarkReadData {
  chatPartnerId: string;
}

interface StatusCheckData {
  partnerId: string;
}

interface JwtPayload {
  sub?: string;
  userId?: string;
  isAdmin?: boolean;
}

@WebSocketGateway({
  namespace: '/chat',
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true,
  },
  transports: ['websocket'],
  pingInterval: 15000,
  pingTimeout: 10000,
  connectTimeout: 10000,
  maxHttpBufferSize: 1e6,
})
export class ChatGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(ChatGateway.name);
  private readonly userSockets = new Map<string, Set<string>>();
  private readonly socketMeta = new Map<string, SocketMeta>();

  constructor(
    private readonly jwtService: JwtService,
    private readonly chatService: ChatService,
    private readonly firebaseService: FirebaseService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ==========================================
  // LIFECYCLE HOOKS
  // ==========================================

  async afterInit(): Promise<void> {
    this.logger.log('🚀 Chat Gateway initialized');

    // Reset all users to offline on server startup
    await this.chatService.resetAllOnlineStatuses();

    // Cleanup stale connections every 60 seconds
    setInterval(() => this.cleanupStaleConnections(), 60000);
  }

  async handleConnection(client: Socket): Promise<void> {
    try {
      const token = this.extractToken(client);
      if (!token) {
        this.disconnectWithError(client, 'Authentication required');
        return;
      }
      const payload: JwtPayload = this.jwtService.verify(token);

      const userId = String(payload.sub || payload.userId || '');
      const isAdmin = Boolean(payload.isAdmin);

      console.log(
        `🔑 [WS Auth] userId: ${userId}, isAdmin: ${isAdmin}, payload:`,
        payload,
      );

      if (!userId) {
        this.disconnectWithError(client, 'Invalid user ID in token');
        return;
      }

      // Store socket metadata
      this.socketMeta.set(client.id, { userId, isAdmin });

      // Track user sockets
      if (!this.userSockets.has(userId)) {
        this.userSockets.set(userId, new Set());
      }
      const userSocketSet = this.userSockets.get(userId);
      if (userSocketSet) {
        userSocketSet.add(client.id);
      }

      // Join rooms
      await client.join(`user:${userId}`);
      if (isAdmin) {
        await client.join('admins');
      }

      // Update online status if first connection
      const connections = this.userSockets.get(userId);
      if (connections && connections.size === 1) {
        await this.chatService.updateUserStatus(userId, true);
        // ✅ Use targeted broadcast instead of global emit
        await this.broadcastStatusToConversations(userId, true);
        this.logger.log(`🟢 User ${userId} online`);
      }

      // Confirm connection
      client.emit('connected', {
        userId,
        isAdmin,
        timestamp: new Date().toISOString(),
      });

      this.logger.log(
        `🔗 Client connected: ${client.id} (User: ${userId}, Admin: ${isAdmin})`,
      );
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Auth failed for ${client.id}: ${errorMessage}`);
      this.disconnectWithError(client, 'Invalid token');
    }
  }

  async handleDisconnect(client: Socket): Promise<void> {
    const meta = this.socketMeta.get(client.id);
    if (!meta) return;

    const { userId } = meta;

    // Clean up socket metadata
    this.socketMeta.delete(client.id);

    // Clean up user sockets
    const userConnections = this.userSockets.get(userId);
    if (userConnections) {
      userConnections.delete(client.id);

      if (userConnections.size === 0) {
        this.userSockets.delete(userId);

        // User is fully offline
        await this.chatService.updateUserStatus(userId, false);
        // ✅ Use targeted broadcast instead of global emit
        await this.broadcastStatusToConversations(
          userId,
          false,
          new Date().toISOString(),
        );

        this.logger.log(`🔴 User ${userId} offline`);
      }
    }

    this.logger.log(`🔌 Client disconnected: ${client.id}`);
  }

  // ==========================================
  // MESSAGE HANDLERS
  // ==========================================

  @SubscribeMessage('send_message')
  async handleMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: SendMessageData,
  ): Promise<void> {
    const sender = this.socketMeta.get(client.id);
    if (!sender) {
      client.emit('error', {
        code: 'AUTH_REQUIRED',
        message: 'Not authenticated',
      });
      return;
    }

    try {
      // Validate
      if (!data.receiverId) {
        throw new Error('Receiver ID is required');
      }

      if (data.type === 'text' && !data.content?.trim()) {
        throw new Error('Message content is required');
      }

      // Send message via service
      const message = await this.chatService.sendMessage(
        sender.userId,
        data.receiverId,
        data.content || '',
        data.type || 'text',
        data.mediaUrl,
      );

      // Confirm to sender
      client.emit('message_sent', message);

      // Send to receiver via WebSocket
      this.server.to(`user:${data.receiverId}`).emit('new_message', message);

      // Send push notification
      await this.sendPushNotification(
        sender.userId,
        data.receiverId,
        data.content,
        data.type || 'text',
        message.id,
      );

      // Create in-app notification
      await this.createInAppNotification(
        sender.userId,
        data.receiverId,
        data.content,
        data.type || 'text',
      );
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Message send failed: ${errorMessage}`);
      client.emit('error', { message: errorMessage });
    }
  }

  @SubscribeMessage('mark_read')
  async handleMarkRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: MarkReadData,
  ): Promise<void> {
    const user = this.socketMeta.get(client.id);
    if (!user) return;

    try {
      const result = await this.chatService.markAsRead(
        user.userId,
        data.chatPartnerId,
      );
      this.logger.log(
        `✅ Marked ${result.count} messages as read: ${user.userId} → ${data.chatPartnerId}`,
      );
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Mark read failed: ${errorMessage}`);
    }
  }

  @SubscribeMessage('check_status')
  handleStatusCheck(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: StatusCheckData,
  ): void {
    const userConnections = this.userSockets.get(data.partnerId);
    const isOnline = userConnections ? userConnections.size > 0 : false;

    client.emit('partner_status', {
      userId: data.partnerId,
      isOnline,
    });
  }

  // ==========================================
  // PUBLIC HELPERS
  // ==========================================

  isUserOnline(userId: string): boolean {
    const connections = this.userSockets.get(userId);
    return connections ? connections.size > 0 : false;
  }

  // ==========================================
  // PRIVATE HELPERS
  // ==========================================

  // ✅ NEW: Targeted broadcast to only relevant partners
  private async broadcastStatusToConversations(
    userId: string,
    isOnline: boolean,
    lastSeen?: string,
  ): Promise<void> {
    try {
      const partnerIds: string[] = [];

      // Get user conversations (works for both regular users and admins)
      try {
        const userConversations =
          await this.chatService.getUserConversations(userId);
        userConversations.forEach((c: any) => {
          if (c.userId) partnerIds.push(c.userId);
        });
      } catch (e) {
        // User might not have regular conversations, that's ok
      }

      // If user is admin, also get admin conversations
      try {
        const user = await this.chatService.getUserById(userId);
        if (user?.isAdmin) {
          const adminConversations =
            await this.chatService.getAdminConversations(userId);
          adminConversations.forEach((c: any) => {
            if (c.userId) partnerIds.push(c.userId);
          });
        }
      } catch (e) {
        // Ignore errors here
      }

      // Remove duplicates and the user themselves
      const uniquePartnerIds = [
        ...new Set(partnerIds.filter((id) => id !== userId)),
      ];

      if (uniquePartnerIds.length > 0) {
        // Emit to each partner's room
        uniquePartnerIds.forEach((partnerId) => {
          this.server.to(`user:${partnerId}`).emit('partner_status', {
            userId,
            isOnline,
            lastSeen: lastSeen || null,
          });
        });

        this.logger.log(
          `📡 Broadcasted status to ${uniquePartnerIds.length} partners of user ${userId}`,
        );
      } else {
        this.logger.log(
          `ℹ️ No conversation partners found for user ${userId}, skipping broadcast`,
        );
      }
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to broadcast status: ${errorMessage}`);
      // Fallback: broadcast to all connected clients
      this.server.emit('partner_status', {
        userId,
        isOnline,
        lastSeen: lastSeen || null,
      });
    }
  }

  private extractToken(client: Socket): string | null {
    const authToken = client.handshake.auth?.token as string | undefined;
    const queryToken = client.handshake.query?.token as string | undefined;
    const authHeader = client.handshake.headers?.authorization;

    if (authToken) return authToken;
    if (queryToken) return queryToken;
    if (authHeader) return authHeader.replace('Bearer ', '');

    return null;
  }

  private disconnectWithError(client: Socket, message: string): void {
    client.emit('error', { message });
    setTimeout(() => client.disconnect(true), 100);
  }

  private cleanupStaleConnections(): void {
    try {
      const sockets = this.server?.sockets?.sockets;
      if (!sockets) return;

      let cleanedCount = 0;
      sockets.forEach((socket: Socket, socketId: string) => {
        if (!this.socketMeta.has(socketId)) {
          this.logger.warn(`Cleaning up stale socket: ${socketId}`);
          socket.disconnect(true);
          cleanedCount++;
        }
      });

      if (cleanedCount > 0) {
        this.logger.log(`Cleaned up ${cleanedCount} stale connections`);
      }
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.debug(`Cleanup routine: ${errorMessage}`);
    }
  }

  private async sendPushNotification(
    senderId: string,
    receiverId: string,
    content?: string,
    type: string = 'text',
    messageId?: string,
  ): Promise<void> {
    try {
      const senderUser = await this.chatService.getUserById(senderId);
      const senderName = senderUser?.name || 'Someone';

      const notificationBody =
        type === 'image'
          ? '📷 Photo'
          : content?.substring(0, 100) || 'New message';

      const deviceTokens =
        await this.chatService.getUserDeviceTokens(receiverId);

      if (deviceTokens.length > 0) {
        await this.firebaseService.sendMulticastNotification(
          deviceTokens,
          senderName,
          notificationBody,
          {
            type: 'new_message',
            senderId,
            receiverId,
            messageId: messageId || '',
          },
        );
        this.logger.log(`📱 Push notification sent to ${receiverId}`);
      } else {
        this.logger.log(`ℹ️ No device tokens for ${receiverId}, skipping push`);
      }
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Push notification failed: ${errorMessage}`);
    }
  }

  private async createInAppNotification(
    senderId: string,
    receiverId: string,
    content?: string,
    type: string = 'text',
  ): Promise<void> {
    try {
      const senderUser = await this.chatService.getUserById(senderId);
      const senderName = senderUser?.name || 'Someone';

      const notificationBody =
        type === 'image'
          ? '📷 Photo'
          : content?.substring(0, 100) || 'New message';

      const notificationDto: CreateNotificationDto = {
        userId: receiverId,
        type: NotificationType.MESSAGE,
        title: `New message from ${senderName}`,
        message: notificationBody,
        actionText: 'View',
        actionLink: `/chat/${senderId}`,
      };

      const notification =
        await this.notificationsService.create(notificationDto);

      this.server.to(`user:${receiverId}`).emit('new_notification', {
        id: notification.id,
        type: 'message',
        title: `New message from ${senderName}`,
        message: notificationBody,
        actionText: 'View',
        actionLink: `/chat/${senderId}`,
        createdAt: new Date().toISOString(),
        isRead: false,
      });
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`In-app notification failed: ${errorMessage}`);
    }
  }
}
