// src/chat/chat.gateway.ts
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
import { Namespace, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { Redis } from '@upstash/redis';
import { ChatService } from './chat.service';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/notification.entity';
import { LogSanitizer } from '../common/utils/log-sanitizer.util';

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
  server!: Namespace;

  private readonly logger = new Logger(ChatGateway.name);
  private readonly isProduction: boolean;

  private readonly PRESENCE_TTL = 120;
  private readonly SOCKET_TTL = 3600;

  constructor(
    private readonly jwtService: JwtService,
    private readonly chatService: ChatService,
    @Inject(forwardRef(() => NotificationsService))
    private readonly notificationsService: NotificationsService,
    @Inject('REDIS_CLIENT') private readonly redis: Redis,
  ) {
    this.isProduction = process.env.NODE_ENV === 'production';
  }

  // ==========================================
  // LIFECYCLE HOOKS
  // ==========================================

  afterInit(): void {
    this.logger.log('🚀 Chat Gateway WebSocket initialized (Redis Mode)');
  }

  async onApplicationBootstrap(): Promise<void> {
    this.logger.log('🚀 Application bootstrap - resetting presence state');

    try {
      await this.redis.del('online_users');

      const socketKeys = await this.redis.keys('socket:*');
      if (socketKeys.length > 0) {
        await this.redis.del(...socketKeys);
      }

      const userSocketKeys = await this.redis.keys('user_sockets:*');
      if (userSocketKeys.length > 0) {
        await this.redis.del(...userSocketKeys);
      }

      const userOnlineKeys = await this.redis.keys('user_online:*');
      if (userOnlineKeys.length > 0) {
        await this.redis.del(...userOnlineKeys);
      }

      await this.chatService.resetAllOnlineStatuses();
      this.logger.log('✅ Reset all online statuses successfully');
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`❌ Failed to reset online statuses: ${errorMessage}`);
    }
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

      if (!userId || userId === 'undefined') {
        this.disconnectWithError(client, 'Invalid user ID in token');
        return;
      }

      // Store socket metadata
      await this.redis.hset(`socket:${client.id}`, {
        userId,
        isAdmin: String(isAdmin),
      });
      await this.redis.expire(`socket:${client.id}`, this.SOCKET_TTL);

      // Refresh presence
      await this.refreshPresence(userId, client.id);

      // Join rooms
      await client.join(`user:${userId}`);

      if (isAdmin) {
        await client.join('admins');
      }

      // Update DB + broadcast online
      await this.chatService.updateUserStatus(userId, true);
      await this.broadcastStatusToConversations(userId, true);

      client.emit('connected', {
        userId,
        isAdmin,
        timestamp: new Date().toISOString(),
      });

      // Safe logging - mask user ID
      this.logger.log(
        `🔗 Client connected: ${client.id.substring(0, 8)}... (User: ${LogSanitizer.maskValue(userId)}, Admin: ${isAdmin})`,
      );
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Auth failed for ${client.id}: ${errorMessage}`);
      this.disconnectWithError(client, 'Invalid token');
    }
  }

  async handleDisconnect(client: Socket): Promise<void> {
    try {
      const meta = await this.redis.hgetall(`socket:${client.id}`);
      if (!meta || !meta.userId) return;

      const userId = String(meta.userId);

      // Clean up this specific socket
      await this.redis.del(`socket:${client.id}`);
      await this.redis.srem(`user_sockets:${userId}`, client.id);

      // Check remaining sockets for this user
      const remainingSockets = await this.redis.smembers(
        `user_sockets:${userId}`,
      );

      const isStillOnline = this.hasActiveSockets(remainingSockets);

      if (!isStillOnline) {
        await Promise.all([
          this.redis.srem('online_users', userId),
          this.redis.del(`user_sockets:${userId}`),
          this.redis.del(`user_online:${userId}`),
        ]);

        await this.chatService.updateUserStatus(userId, false);
        await this.broadcastStatusToConversations(
          userId,
          false,
          new Date().toISOString(),
        );

        this.logger.log(`🔴 User offline`);
      } else {
        await Promise.all([
          this.redis.expire(`user_sockets:${userId}`, this.SOCKET_TTL),
          this.redis.set(`user_online:${userId}`, '1', {
            ex: this.PRESENCE_TTL,
          }),
          this.redis.sadd('online_users', userId),
        ]);

        this.logger.log(
          `🟢 User still online with ${remainingSockets.length} socket(s)`,
        );
      }

      this.logger.log(
        `🔌 Client disconnected: ${client.id.substring(0, 8)}...`,
      );
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Disconnect error: ${errorMessage}`);
    }
  }

  // ==========================================
  // WEBSOCKET EVENT HANDLERS
  // ==========================================

  @SubscribeMessage('user_deleted')
  async handleUserDeleted(
    @MessageBody() data: { userId: string },
  ): Promise<void> {
    try {
      const partnerIds = await this.chatService.getConversationPartnerIds(
        data.userId,
      );

      partnerIds.forEach((partnerId) => {
        this.server.to(`user:${partnerId}`).emit('user_deleted', {
          deletedUserId: data.userId,
        });
      });
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`User deleted event error: ${errorMessage}`);
    }
  }

  @SubscribeMessage('heartbeat')
  async handleHeartbeat(@ConnectedSocket() client: Socket): Promise<void> {
    try {
      const meta = await this.redis.hgetall(`socket:${client.id}`);
      if (!meta?.userId) return;

      const userId = String(meta.userId);

      await this.redis.expire(`socket:${client.id}`, this.SOCKET_TTL);
      await this.refreshPresence(userId, client.id);
    } catch (error) {
      this.logger.debug(`Heartbeat error`);
    }
  }

  @SubscribeMessage('typing')
  async handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { receiverId: string; isTyping: boolean },
  ): Promise<void> {
    try {
      const meta = await this.redis.hgetall(`socket:${client.id}`);
      if (!meta?.userId) return;

      this.server.to(`user:${data.receiverId}`).emit('typing', {
        senderId: String(meta.userId),
        isTyping: data.isTyping,
      });
    } catch (error) {
      this.logger.error(`Typing event error`);
    }
  }

  @SubscribeMessage('send_message')
  async handleMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: SendMessageData,
  ): Promise<void> {
    try {
      const meta = await this.redis.hgetall(`socket:${client.id}`);
      if (!meta?.userId) {
        client.emit('error', {
          code: 'AUTH_REQUIRED',
          message: 'Not authenticated',
        });
        return;
      }

      const senderId = String(meta.userId);

      if (!data.receiverId) {
        throw new Error('Receiver ID is required');
      }

      if (data.type === 'text' && !data.content?.trim()) {
        throw new Error('Message content is required');
      }

      // Save to database
      const message = await this.chatService.sendMessage(
        senderId,
        data.receiverId,
        data.content || '',
        data.type || 'text',
        data.mediaUrl,
      );

      // Confirm to sender immediately
      client.emit('message_sent', message);

      // Emit to receiver's room
      const receiverRoom = `user:${data.receiverId}`;
      this.server.to(receiverRoom).emit('new_message', message);

      // Emit to sender's room for multi-device sync
      const senderRoom = `user:${senderId}`;
      this.server.to(senderRoom).emit('new_message', message);

      // Push notification if receiver offline
      const isReceiverOnline = await this.isUserOnline(data.receiverId);
      if (!isReceiverOnline) {
        this.sendPushNotification(senderId, data).catch((err) =>
          this.logger.error(`Push notification failed`),
        );
      }
    } catch (error) {
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
    try {
      const meta = await this.redis.hgetall(`socket:${client.id}`);
      if (!meta?.userId) return;

      const userId = String(meta.userId);

      const result = await this.chatService.markAsRead(
        userId,
        data.chatPartnerId,
      );

      const readReceipt = {
        readerId: userId,
        conversationId: result.conversationId,
        count: result.count,
        timestamp: new Date().toISOString(),
      };

      this.server
        .to(`user:${data.chatPartnerId}`)
        .emit('message_read', readReceipt);

      client.emit('message_read', readReceipt);
    } catch (error) {
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
    try {
      const isOnline = await this.isUserOnline(data.partnerId);

      client.emit('partner_status', {
        userId: data.partnerId,
        isOnline,
      });
    } catch (error) {
      this.logger.error(`Status check error`);
    }
  }

  // ==========================================
  // PUBLIC HELPERS
  // ==========================================

  async isUserOnline(userId: string): Promise<boolean> {
    try {
      const onlineTtl = await this.redis.exists(`user_online:${userId}`);
      if (!onlineTtl) return false;

      const userSockets = await this.redis.smembers(`user_sockets:${userId}`);
      if (!userSockets.length) return false;

      return this.hasActiveSockets(userSockets);
    } catch (error) {
      this.logger.error(`Redis isUserOnline error`);
      return false;
    }
  }

  async getOnlineUsers(): Promise<string[]> {
    try {
      return await this.redis.smembers('online_users');
    } catch (error) {
      this.logger.error(`Redis getOnlineUsers error`);
      return [];
    }
  }

  // ==========================================
  // PRIVATE HELPERS
  // ==========================================

  private get socketsMap(): Map<string, Socket> | undefined {
    const serverAny = this.server as any;
    if (!serverAny) return undefined;

    if (serverAny.sockets instanceof Map) {
      return serverAny.sockets;
    }

    return serverAny.sockets?.sockets;
  }

  private hasActiveSockets(socketIds: string[]): boolean {
    if (!socketIds.length) return false;

    const socketsMap = this.socketsMap;

    if (!socketsMap) {
      return socketIds.length > 0;
    }

    const hasLocalConnected = socketIds.some((socketId) => {
      const socket = socketsMap.get(socketId);
      return socket?.connected === true;
    });

    if (hasLocalConnected) return true;

    const hasUnknownSocket = socketIds.some(
      (socketId) => !socketsMap.has(socketId),
    );

    if (hasUnknownSocket) return true;

    return false;
  }

  private async refreshPresence(
    userId: string,
    socketId: string,
  ): Promise<void> {
    await Promise.all([
      this.redis.sadd(`user_sockets:${userId}`, socketId),
      this.redis.expire(`user_sockets:${userId}`, this.SOCKET_TTL),
      this.redis.set(`user_online:${userId}`, '1', {
        ex: this.PRESENCE_TTL,
      }),
      this.redis.sadd('online_users', userId),
    ]);
  }

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

  private async sendPushNotification(
    senderId: string,
    data: SendMessageData,
  ): Promise<void> {
    try {
      const senderUser = await this.chatService.getUserById(senderId);
      const senderName = senderUser?.name || 'Someone';
      const notificationBody = this.getNotificationBody(data);

      await this.notificationsService.create({
        userId: data.receiverId,
        type: NotificationType.MESSAGE,
        title: `New message from ${senderName}`,
        message: notificationBody,
        actionText: 'Reply',
        actionLink: `/chat/${senderId}`,
      });
    } catch (error) {
      this.logger.error(`Push notification error`);
    }
  }

  private async broadcastStatusToConversations(
    userId: string,
    isOnline: boolean,
    lastSeen?: string,
  ): Promise<void> {
    try {
      const partnerIds =
        await this.chatService.getConversationPartnerIds(userId);

      if (!partnerIds.length) return;

      const payload = {
        userId,
        isOnline,
        lastSeen: lastSeen ?? null,
      };

      for (const partnerId of partnerIds) {
        this.server.to(`user:${partnerId}`).emit('partner_status', payload);
      }

      this.server.to(`user:${userId}`).emit('partner_status', payload);

      this.logger.log(`📡 Broadcast status to ${partnerIds.length} partners`);
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to broadcast status: ${errorMessage}`);
    }
  }

  private extractToken(client: Socket): string | null {
    const authToken = client.handshake.auth?.token as string | undefined;
    const queryToken = client.handshake.query?.token as string | undefined;
    const authHeader = client.handshake.headers?.authorization as
      | string
      | undefined;

    if (authToken) return authToken;
    if (queryToken) return queryToken;
    if (authHeader) return authHeader.replace('Bearer ', '');

    return null;
  }

  private disconnectWithError(client: Socket, message: string): void {
    client.emit('error', { message });
    setTimeout(() => client.disconnect(true), 100);
  }
}
