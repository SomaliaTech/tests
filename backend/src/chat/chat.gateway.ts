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

  // Reduced TTLs for faster offline detection when app is killed
  private readonly PRESENCE_TTL = 60; // 60 seconds
  private readonly SOCKET_TTL = 120; // 120 seconds

  constructor(
    private readonly jwtService: JwtService,
    private readonly chatService: ChatService,
    @Inject(forwardRef(() => NotificationsService))
    private readonly notificationsService: NotificationsService,
    @Inject('REDIS_CLIENT') private readonly redis: Redis,
  ) {
    this.isProduction = process.env.NODE_ENV === 'production';
  }

  afterInit(): void {
    this.logger.log('🚀 Chat Gateway WebSocket initialized (Redis Mode)');
  }

  async onApplicationBootstrap(): Promise<void> {
    this.logger.log('🚀 Application bootstrap - resetting presence state');
    try {
      await this.redis.del('online_users');

      // Clean up stale socket keys on startup
      const socketKeys = await this.redis.keys('socket:*');
      if (socketKeys.length > 0) await this.redis.del(...socketKeys);

      const userSocketKeys = await this.redis.keys('user_sockets:*');
      if (userSocketKeys.length > 0) await this.redis.del(...userSocketKeys);

      const userOnlineKeys = await this.redis.keys('user_online:*');
      if (userOnlineKeys.length > 0) await this.redis.del(...userOnlineKeys);

      await this.chatService.resetAllOnlineStatuses();
      this.logger.log('✅ Reset all online statuses successfully');
    } catch (error) {
      this.logger.error(`❌ Failed to reset online statuses: ${error}`);
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

      // Store socket metadata with TTL
      await this.redis.hset(`socket:${client.id}`, {
        userId,
        isAdmin: String(isAdmin),
      });
      await this.redis.expire(`socket:${client.id}`, this.SOCKET_TTL);

      await this.refreshPresence(userId, client.id);

      await client.join(`user:${userId}`);
      if (isAdmin) await client.join('admins');

      await this.chatService.updateUserStatus(userId, true);

      // 🚀 OPTIMIZED: Only broadcast to recent active chats, NOT all DB partners
      await this.broadcastStatusToConversations(userId, true);

      client.emit('connected', {
        userId,
        isAdmin,
        timestamp: new Date().toISOString(),
      });

      this.logger.log(
        `🔗 Client connected: ${client.id.substring(0, 8)}... (User: ${LogSanitizer.maskValue(userId)})`,
      );
    } catch (error) {
      this.logger.error(`Auth failed for ${client.id}: ${error}`);
      this.disconnectWithError(client, 'Invalid token');
    }
  }

  async handleDisconnect(client: Socket): Promise<void> {
    try {
      const socketId = client.id;
      const socketKey = `socket:${socketId}`;

      const meta = await this.redis.hgetall(socketKey);
      if (!meta || !meta.userId) return;

      const userId = String(meta.userId);

      // 1. Remove this specific socket from Redis
      await this.redis.del(socketKey);
      await this.redis.srem(`user_sockets:${userId}`, socketId);

      // 2. 🚀 CRITICAL FIX: Clean up stale sockets (Fixes Ghost Users from server crashes)
      const remainingSockets = await this.redis.smembers(
        `user_sockets:${userId}`,
      );
      const activeSockets: string[] = [];

      if (remainingSockets.length > 0) {
        const checks = await Promise.all(
          remainingSockets.map(async (sId) => {
            const exists = await this.redis.exists(`socket:${sId}`);
            return { sId, exists };
          }),
        );

        for (const check of checks) {
          if (check.exists) {
            activeSockets.push(check.sId);
          } else {
            // Stale socket from a crashed server instance - purge it
            await this.redis.srem(`user_sockets:${userId}`, check.sId);
          }
        }
      }

      // 3. If no active sockets remain, mark user truly offline
      if (activeSockets.length === 0) {
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

        this.logger.log(`🔴 User offline: ${LogSanitizer.maskValue(userId)}`);
      } else {
        // Refresh TTLs for remaining active sockets
        await Promise.all([
          this.redis.expire(`user_sockets:${userId}`, this.SOCKET_TTL),
          this.redis.set(`user_online:${userId}`, '1', {
            ex: this.PRESENCE_TTL,
          }),
          this.redis.sadd('online_users', userId),
        ]);
      }
    } catch (error) {
      this.logger.error(`Disconnect error: ${error}`);
    }
  }

  // ==========================================
  // WEBSOCKET EVENT HANDLERS
  // ==========================================

  @SubscribeMessage('heartbeat')
  async handleHeartbeat(@ConnectedSocket() client: Socket): Promise<void> {
    try {
      const meta = await this.redis.hgetall(`socket:${client.id}`);
      if (!meta?.userId) return;

      const userId = String(meta.userId);

      // Refresh TTLs on heartbeat
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
      if (!data.receiverId) throw new Error('Receiver ID is required');
      if (data.type === 'text' && !data.content?.trim())
        throw new Error('Message content is required');

      // 🚀 Track active chats in Redis for O(1) broadcasting later
      await Promise.all([
        this.redis.sadd(`active_chats:${senderId}`, data.receiverId),
        this.redis.sadd(`active_chats:${data.receiverId}`, senderId),
        this.redis.expire(`active_chats:${senderId}`, 86400), // 24 hours
        this.redis.expire(`active_chats:${data.receiverId}`, 86400),
      ]);

      const message = await this.chatService.sendMessage(
        senderId,
        data.receiverId,
        data.content || '',
        data.type || 'text',
        data.mediaUrl,
      );

      client.emit('message_sent', message);

      const receiverRoom = `user:${data.receiverId}`;
      this.server.to(receiverRoom).emit('new_message', message);

      const senderRoom = `user:${senderId}`;
      this.server.to(senderRoom).emit('new_message', message);

      const isReceiverOnline = await this.isUserOnline(data.receiverId);
      if (!isReceiverOnline) {
        this.sendPushNotification(senderId, data).catch((err) =>
          this.logger.error(`Push notification failed`),
        );
      }
    } catch (error) {
      this.logger.error(`Message send failed: ${error}`);
      client.emit('error', {
        message: error instanceof Error ? error.message : 'Unknown error',
      });
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
      this.logger.error(`Mark read failed: ${error}`);
    }
  }

  @SubscribeMessage('check_status')
  async handleStatusCheck(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: StatusCheckData,
  ): Promise<void> {
    try {
      const isOnline = await this.isUserOnline(data.partnerId);
      client.emit('partner_status', { userId: data.partnerId, isOnline });
    } catch (error) {
      this.logger.error(`Status check error`);
    }
  }

  // ==========================================
  // PUBLIC HELPERS
  // ==========================================

  async isUserOnline(userId: string): Promise<boolean> {
    try {
      const isOnlineInRedis = await this.redis.exists(`user_online:${userId}`);

      if (!isOnlineInRedis) {
        // 🚀 LAZY FIX: If Redis says offline, ensure DB is also offline
        this.chatService.ensureUserOffline(userId).catch(() => {});
        return false;
      }

      return true;
    } catch (error) {
      this.logger.error(`Redis isUserOnline error`);
      return false;
    }
  }

  async getOnlineUsers(): Promise<string[]> {
    try {
      return await this.redis.smembers('online_users');
    } catch (error) {
      return [];
    }
  }

  // ==========================================
  // PRIVATE HELPERS
  // ==========================================

  private async refreshPresence(
    userId: string,
    socketId: string,
  ): Promise<void> {
    await Promise.all([
      this.redis.sadd(`user_sockets:${userId}`, socketId),
      this.redis.expire(`user_sockets:${userId}`, this.SOCKET_TTL),
      this.redis.set(`user_online:${userId}`, '1', { ex: this.PRESENCE_TTL }),
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

      await this.notificationsService.create({
        userId: data.receiverId,
        type: NotificationType.MESSAGE,
        title: `New message from ${senderName}`,
        message: this.getNotificationBody(data),
        actionText: 'Reply',
        actionLink: `/chat/${senderId}`,
      });
    } catch (error) {
      this.logger.error(`Push notification error`);
    }
  }

  // 🚀 OPTIMIZED: Broadcast only to recent active chats, NOT all DB partners
  private async broadcastStatusToConversations(
    userId: string,
    isOnline: boolean,
    lastSeen?: string,
  ): Promise<void> {
    try {
      const payload = { userId, isOnline, lastSeen: lastSeen ?? null };

      // 1. Always emit to own room for multi-device sync
      this.server.to(`user:${userId}`).emit('partner_status', payload);

      // 2. Emit to recent active chats (Max 50 to prevent spam/DoS at scale)
      const activePartners = await this.redis.smembers(
        `active_chats:${userId}`,
      );

      if (activePartners.length > 0) {
        const limitedPartners = activePartners.slice(0, 50);
        for (const partnerId of limitedPartners) {
          this.server.to(`user:${partnerId}`).emit('partner_status', payload);
        }
      }

      // If admin, emit to 'admins' room so other admins see it
      const user = await this.chatService.getUserById(userId);
      if (user?.isAdmin || user?.isSuperAdmin) {
        this.server.to('admins').emit('partner_status', payload);
      }
    } catch (error) {
      this.logger.error(`Failed to broadcast status: ${error}`);
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
