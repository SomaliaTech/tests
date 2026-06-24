import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ChatService } from './chat.service';

@WebSocketGateway({
  cors: {
    origin: '*',
    credentials: true,
  },
  namespace: '/chat',
  transports: ['websocket', 'polling'],
  pingTimeout: 60000,
  pingInterval: 25000,
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;

  private connectedUsers: Map<string, { userId: string; isAdmin: boolean }> =
    new Map();
  // ✅ Track online users for quick lookup
  private onlineUsers: Set<string> = new Set();

  constructor(
    private jwtService: JwtService,
    private chatService: ChatService,
  ) {}

  async handleConnection(client: Socket) {
    try {
      console.log('🔌 New WebSocket connection attempt:', client.id);

      let token = client.handshake.auth.token;
      if (!token) {
        token = client.handshake.query.token as string;
      }
      if (!token) {
        token = client.handshake.headers.authorization?.replace('Bearer ', '');
      }

      if (!token) {
        console.log('❌ No token provided, disconnecting');
        client.emit('error', { message: 'Authentication required' });
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify(token);
      const userId = payload.sub;
      const isAdmin = payload.isAdmin || false;

      // Store connection
      this.connectedUsers.set(client.id, { userId, isAdmin });
      this.onlineUsers.add(userId);

      // Join user's personal room
      client.join(`user_${userId}`);

      // Update status in database
      await this.chatService.updateUserStatus(userId, true);

      // ✅ Broadcast to ALL connected clients that this user is online
      this.server.emit('user_status', {
        userId,
        isOnline: true,
        timestamp: new Date().toISOString(),
      });

      console.log(`✅ WebSocket Connected: ${userId} (Admin: ${isAdmin})`);
      console.log(`📊 Online users: ${this.onlineUsers.size}`);

      // Send connection confirmation
      client.emit('connected', {
        status: 'ok',
        userId,
        onlineUsers: Array.from(this.onlineUsers),
      });
    } catch (error) {
      console.error('❌ WS Auth Failed:', error.message);
      client.emit('error', {
        message: 'Authentication failed: ' + error.message,
      });
      client.disconnect();
    }
  }

  async handleDisconnect(client: Socket) {
    const userData = this.connectedUsers.get(client.id);
    if (userData) {
      this.connectedUsers.delete(client.id);

      // Check if user has other active connections
      const hasOtherConnections = Array.from(this.connectedUsers.values()).some(
        (u) => u.userId === userData.userId,
      );

      if (!hasOtherConnections) {
        this.onlineUsers.delete(userData.userId);

        // Update status in database
        await this.chatService.updateUserStatus(userData.userId, false);

        // ✅ Broadcast to ALL that this user is offline
        this.server.emit('user_status', {
          userId: userData.userId,
          isOnline: false,
          timestamp: new Date().toISOString(),
        });
      }

      console.log(`❌ Disconnected: ${userData.userId}`);
      console.log(`📊 Online users: ${this.onlineUsers.size}`);
    }
  }

  @SubscribeMessage('send_message')
  async handleMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: {
      receiverId: string;
      content?: string;
      type: string;
      mediaUrl?: string;
    },
  ) {
    console.log('📨 Received send_message:', {
      from: this.connectedUsers.get(client.id)?.userId,
      to: data.receiverId,
      type: data.type,
    });

    const senderData = this.connectedUsers.get(client.id);
    if (!senderData) {
      console.log('❌ Sender not found');
      client.emit('error', { message: 'Sender not authenticated' });
      return;
    }

    try {
      // Validate permission
      await this.chatService.validateMessagePermission(
        senderData.userId,
        data.receiverId,
        senderData.isAdmin,
      );

      // Save message (this also creates conversation if needed)
      const savedMsg = await this.chatService.saveMessage(
        senderData.userId,
        data.receiverId,
        data.content || '',
        data.type,
        data.mediaUrl,
      );

      console.log('✅ Message saved:', savedMsg.id);

      // Send confirmation to sender
      client.emit('message_sent', savedMsg);

      // Send to receiver
      this.server.to(`user_${data.receiverId}`).emit('new_message', savedMsg);

      // If sender is in multiple tabs, update other tabs too
      client.broadcast
        .to(`user_${senderData.userId}`)
        .emit('new_message', savedMsg);
    } catch (error: any) {
      console.error('❌ Error handling message:', error.message);
      client.emit('error', { message: error.message });
    }
  }

  @SubscribeMessage('mark_read')
  async handleMarkRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { chatPartnerId: string },
  ) {
    const userData = this.connectedUsers.get(client.id);
    if (!userData) return;

    await this.chatService.markAsRead(userData.userId, data.chatPartnerId);

    // Notify partner that messages were read
    this.server.to(`user_${data.chatPartnerId}`).emit('messages_read', {
      userId: userData.userId,
      timestamp: new Date().toISOString(),
    });
  }

  // ✅ Helper method to check if user is online
  isUserOnline(userId: string): boolean {
    return this.onlineUsers.has(userId);
  }
}
