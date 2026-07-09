import {
  Logger,
  Inject,
  forwardRef,
  OnApplicationBootstrap,
} from '@nestjs/common';
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
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/notification.entity';

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
  implements
    OnGatewayInit,
    OnGatewayConnection,
    OnGatewayDisconnect,
    OnApplicationBootstrap
{
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(ChatGateway.name);

  // In-memory storage to replace Redis
  private readonly socketMeta = new Map<string, SocketMeta>();
  private readonly onlineUsers = new Set<string>();
  private readonly userSockets = new Map<string, Set<string>>();
  private readonly socketTTLs = new Map<string, NodeJS.Timeout>();

  constructor(
    private readonly jwtService: JwtService,
    private readonly chatService: ChatService,
    @Inject(forwardRef(() => NotificationsService))
    private readonly notificationsService: NotificationsService,
  ) {}

  // ==========================================
  // LIFECYCLE HOOKS
  // ==========================================

  afterInit(): void {
    this.logger.log('🚀 Chat Gateway WebSocket initialized (In-Memory Mode)');
  }

  async onApplicationBootstrap(): Promise<void> {
    this.logger.log('🚀 Application bootstrap - all modules ready');

    try {
      // Reset all online statuses in the database
      await this.chatService.resetAllOnlineStatuses();
      this.logger.log('✅ Reset all online statuses successfully');
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`❌ Failed to reset online statuses: ${errorMessage}`);
    }

    // Cleanup stale connections periodically
    setInterval(() => this.cleanupStaleConnections(), 60000);
  }

  // ==========================================
  // CONNECTION HANDLERS
  // ==========================================

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

      if (!userId) {
        this.disconnectWithError(client, 'Invalid user ID in token');
        return;
      }

      // Store socket metadata locally
      this.socketMeta.set(client.id, { userId, isAdmin });

      // Track socket in memory
      if (!this.userSockets.has(userId)) {
        this.userSockets.set(userId, new Set());
      }
      this.userSockets.get(userId)!.add(client.id);

      // Track online user
      const wasOffline = !this.onlineUsers.has(userId);
      if (wasOffline) {
        this.onlineUsers.add(userId);
      }

      // Start TTL timer for this user
      this.startSocketTTL(userId, client.id);

      // Join rooms
      await client.join(`user:${userId}`);
      if (isAdmin) {
        await client.join('admins');
      }

      // Update online status if first connection
      if (wasOffline) {
        await this.chatService.updateUserStatus(userId, true);
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

    // Remove socket from memory
    const sockets = this.userSockets.get(userId);
    if (sockets) {
      sockets.delete(client.id);

      // Clear TTL for this socket
      this.clearSocketTTL(client.id);

      // Check if user has any remaining sockets
      if (sockets.size === 0) {
        // User is fully offline
        this.userSockets.delete(userId);
        this.onlineUsers.delete(userId);

        await this.chatService.updateUserStatus(userId, false);
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
  // WEBSOCKET EVENT HANDLERS
  // ==========================================

  @SubscribeMessage('heartbeat')
  handleHeartbeat(@ConnectedSocket() client: Socket): void {
    const meta = this.socketMeta.get(client.id);
    if (meta) {
      this.refreshSocketTTL(meta.userId, client.id);
    }
  }

  @SubscribeMessage('typing')
  handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { receiverId: string; isTyping: boolean },
  ): void {
    const sender = this.socketMeta.get(client.id);
    if (!sender) return;

    try {
      // Broadcast typing status to the receiver
      this.server.to(`user:${data.receiverId}`).emit('typing', {
        senderId: sender.userId,
        isTyping: data.isTyping,
      });
    } catch (error) {
      this.logger.error(`Typing event error: ${error}`);
    }
  }

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
      if (!data.receiverId) {
        throw new Error('Receiver ID is required');
      }

      if (data.type === 'text' && !data.content?.trim()) {
        throw new Error('Message content is required');
      }

      this.refreshSocketTTL(sender.userId, client.id);

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

      // Check if receiver is online using in-memory storage
      const isReceiverOnline = this.isUserOnline(data.receiverId);

      if (isReceiverOnline) {
        // User is online - send via WebSocket only
        this.server.to(`user:${data.receiverId}`).emit('new_message', message);
        this.logger.debug(
          `📨 Message sent via WebSocket to online user: ${data.receiverId}`,
        );
      } else {
        // User is offline - send push notification
        const senderUser = await this.chatService.getUserById(sender.userId);
        const senderName = senderUser?.name || 'Someone';

        const notificationBody = this.getNotificationBody(data);

        try {
          await this.notificationsService.create({
            userId: data.receiverId,
            type: NotificationType.MESSAGE,
            title: `New message from ${senderName}`,
            message: notificationBody,
            actionText: 'Reply',
            actionLink: `/chat/${sender.userId}`,
          });
          this.logger.log(
            `📨 Push notification sent to offline user: ${data.receiverId}`,
          );
        } catch (error) {
          this.logger.error(
            `Push notification failed for ${data.receiverId}: ${error}`,
          );
        }

        // Still emit WebSocket event for multi-device scenarios
        this.server.to(`user:${data.receiverId}`).emit('new_message', message);
      }
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

      // Emit to partner for read receipts
      this.server.to(`user:${data.chatPartnerId}`).emit('message_read', {
        readerId: user.userId,
        conversationId: result.conversationId,
        count: result.count,
        timestamp: new Date().toISOString(),
      });

      // Confirm to the reader
      client.emit('message_read', {
        readerId: user.userId,
        conversationId: result.conversationId,
        count: result.count,
        timestamp: new Date().toISOString(),
      });
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Mark read failed: ${errorMessage}`);
    }
  }

  @SubscribeMessage('check_status')
  async handleStatusCheck(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: StatusCheckData,
  ): Promise<void> {
    const isOnline = this.isUserOnline(data.partnerId);

    client.emit('partner_status', {
      userId: data.partnerId,
      isOnline,
    });
  }

  // ==========================================
  // PUBLIC HELPERS
  // ==========================================

  isUserOnline(userId: string): boolean {
    const sockets = this.userSockets.get(userId);
    return sockets ? sockets.size > 0 : false;
  }

  getOnlineUsers(): string[] {
    return Array.from(this.onlineUsers);
  }

  // ==========================================
  // PRIVATE HELPERS
  // ==========================================

  private getNotificationBody(data: SendMessageData): string {
    switch (data.type) {
      case 'image':
        return '📷 Photo';
      case 'file':
        return '📎 File';
      default:
        return data.content?.substring(0, 100) || 'New message';
    }
  }

  private async broadcastStatusToConversations(
    userId: string,
    isOnline: boolean,
    lastSeen?: string,
  ): Promise<void> {
    try {
      const partnerIds = new Set<string>();

      // Get all conversation partners
      const [userConversations, user] = await Promise.all([
        this.chatService.getUserConversations(userId).catch(() => []),
        this.chatService.getUserById(userId),
      ]);

      userConversations.forEach((c: any) => {
        if (c.userId) partnerIds.add(c.userId);
      });

      // If admin, also get admin conversations
      if (user?.isAdmin) {
        const adminConversations = await this.chatService
          .getAdminConversations(userId)
          .catch(() => []);
        adminConversations.forEach((c: any) => {
          if (c.userId) partnerIds.add(c.userId);
        });
      }

      // Filter out self
      partnerIds.delete(userId);

      if (partnerIds.size > 0) {
        const statusUpdate = {
          userId,
          isOnline,
          lastSeen: lastSeen || null,
        };

        // Emit to all partners efficiently
        partnerIds.forEach((partnerId) => {
          this.server
            .to(`user:${partnerId}`)
            .emit('partner_status', statusUpdate);
        });

        this.logger.debug(
          `📡 Broadcasted status to ${partnerIds.size} partners`,
        );
      }
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to broadcast status: ${errorMessage}`);
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

  private startSocketTTL(userId: string, socketId: string): void {
    this.clearSocketTTL(socketId);

    const timeout = setTimeout(() => {
      this.logger.warn(`Socket TTL expired for ${socketId} (user: ${userId})`);
      const client = this.server.sockets.sockets.get(socketId);
      if (client) {
        client.disconnect(true);
      }
    }, 60000); // 60 seconds TTL

    this.socketTTLs.set(socketId, timeout);
  }

  private refreshSocketTTL(userId: string, socketId: string): void {
    this.startSocketTTL(userId, socketId);
  }

  private clearSocketTTL(socketId: string): void {
    const timeout = this.socketTTLs.get(socketId);
    if (timeout) {
      clearTimeout(timeout);
      this.socketTTLs.delete(socketId);
    }
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
}
