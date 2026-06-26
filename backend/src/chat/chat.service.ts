import {
  Injectable,
  ForbiddenException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { eq, and, or, desc, sql, asc, inArray, ilike, SQL } from 'drizzle-orm'; // ✅ Added or, ilike
import { v4 as uuidv4 } from 'uuid';
import {
  messages,
  users,
  conversations,
  deviceTokens,
} from '../drizzle/schema';

@Injectable()
export class ChatService {
  constructor(private readonly drizzle: DrizzleService) {}

  // ==========================================
  // USER QUERIES
  // ==========================================

  async getUserById(userId: string) {
    const [user] = await this.drizzle.db
      .select({
        id: users.id,
        name: users.name,
        phoneNumber: users.phoneNumber,
        profileImage: users.profileImage,
        isOnline: users.isOnline,
        lastSeen: users.lastSeen,
        isAdmin: users.isAdmin,
      })
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    return user || null;
  }

  async getAvailableAdmins() {
    return this.drizzle.db
      .select({
        id: users.id,
        name: users.name,
        phoneNumber: users.phoneNumber,
        profileImage: users.profileImage,
        isOnline: users.isOnline,
        lastSeen: users.lastSeen,
      })
      .from(users)
      .where(eq(users.isAdmin, true))
      .orderBy(desc(users.isOnline), asc(users.name))
      .limit(20);
  }

  // ==========================================
  // CONVERSATION MANAGEMENT
  // ==========================================

  async getOrCreateConversation(userId1: string, userId2: string) {
    const [p1, p2] = [userId1, userId2].sort();

    const [existing] = await this.drizzle.db
      .select()
      .from(conversations)
      .where(
        and(
          eq(conversations.participant1, p1),
          eq(conversations.participant2, p2),
        ),
      )
      .limit(1);

    if (existing) return existing;

    const [conversation] = await this.drizzle.db
      .insert(conversations)
      .values({
        id: uuidv4(),
        participant1: p1,
        participant2: p2,
      })
      .returning();

    return conversation;
  }

  async createConversation(userId1: string, userId2: string) {
    await this.validateConversationParticipants(userId1, userId2);
    return this.getOrCreateConversation(userId1, userId2);
  }

  private async validateConversationParticipants(
    userId1: string,
    userId2: string,
  ) {
    if (userId1 === userId2) {
      throw new BadRequestException('Cannot create conversation with yourself');
    }

    const participants = await this.drizzle.db
      .select({ id: users.id, isAdmin: users.isAdmin })
      .from(users)
      .where(inArray(users.id, [userId1, userId2]));

    if (participants.length !== 2) {
      throw new NotFoundException('One or both users not found');
    }

    if (!participants.some((p) => p.isAdmin)) {
      throw new ForbiddenException(
        'Conversations require at least one admin participant',
      );
    }
  }

  // ==========================================
  // MESSAGE MANAGEMENT
  // ==========================================

  async sendMessage(
    senderId: string,
    receiverId: string,
    content: string,
    type: string = 'text',
    mediaUrl?: string,
  ) {
    await this.validateMessagePermission(senderId, receiverId);

    if (type === 'text' && !content?.trim()) {
      throw new BadRequestException('Message content cannot be empty');
    }

    const conversation = await this.getOrCreateConversation(
      senderId,
      receiverId,
    );

    const [message] = await this.drizzle.db
      .insert(messages)
      .values({
        id: uuidv4(),
        conversationId: conversation.id,
        senderId,
        receiverId,
        content: content || null,
        type,
        mediaUrl: mediaUrl || null,
        isRead: false,
      })
      .returning();

    const preview =
      type === 'image'
        ? '📷 Photo'
        : type === 'file'
          ? '📎 File'
          : content?.substring(0, 100) || '';

    await this.drizzle.db
      .update(conversations)
      .set({
        lastMessage: preview,
        lastMessageType: type,
        lastMessageAt: new Date(),
        updatedAt: new Date(),
      })
      .where(eq(conversations.id, conversation.id));

    return message;
  }

  async validateMessagePermission(senderId: string, receiverId: string) {
    const usersData = await this.drizzle.db
      .select({ id: users.id, isAdmin: users.isAdmin })
      .from(users)
      .where(inArray(users.id, [senderId, receiverId]));

    const sender = usersData.find((u) => u.id === senderId);
    const receiver = usersData.find((u) => u.id === receiverId);

    if (!sender) throw new NotFoundException('Sender not found');
    if (!receiver) throw new NotFoundException('Receiver not found');

    if (sender.isAdmin) return;

    if (!receiver.isAdmin) {
      throw new ForbiddenException('You can only message administrators');
    }
  }

  async getMessages(
    userId: string,
    partnerId: string,
    limit: number = 50,
    before?: Date,
  ) {
    await this.validateMessageAccess(userId, partnerId);

    const conversation = await this.getOrCreateConversation(userId, partnerId);

    const conditions = [eq(messages.conversationId, conversation.id)];
    if (before) {
      conditions.push(sql`${messages.createdAt} < ${before.toISOString()}`);
    }

    return this.drizzle.db
      .select()
      .from(messages)
      .where(and(...conditions))
      .orderBy(desc(messages.createdAt))
      .limit(Math.min(limit, 100));
  }

  private async validateMessageAccess(userId: string, partnerId: string) {
    const user = await this.getUserById(userId);
    if (!user) throw new NotFoundException('User not found');

    if (!user.isAdmin) {
      const partner = await this.getUserById(partnerId);
      if (!partner?.isAdmin) {
        throw new ForbiddenException(
          'You can only view messages with administrators',
        );
      }
    }
  }

  async markAsRead(userId: string, partnerId: string) {
    const conversation = await this.getOrCreateConversation(userId, partnerId);

    const result = await this.drizzle.db
      .update(messages)
      .set({ isRead: true, readAt: new Date() })
      .where(
        and(
          eq(messages.conversationId, conversation.id),
          eq(messages.receiverId, userId),
          eq(messages.isRead, false),
        ),
      )
      .returning({ id: messages.id });

    return { count: result.length };
  }

  async getUnreadCount(userId: string) {
    const [result] = await this.drizzle.db
      .select({ count: sql<number>`count(*)::int` })
      .from(messages)
      .where(and(eq(messages.receiverId, userId), eq(messages.isRead, false)));

    return { unreadCount: result?.count || 0 };
  }

  // ==========================================
  // CONVERSATION LISTING
  // ==========================================

  async getAdminConversations(adminId: string) {
    const result = await this.drizzle.db.execute(sql`
    SELECT DISTINCT ON (c.id)
      c.id as "conversationId",
      u.id as "userId",
      u.name,
      u.phone_number as "phoneNumber",
      u.profile_image as "profileImage",
      u.is_online as "isOnline",
      u.last_seen as "lastSeen",
      c.last_message as "lastMessage",
      c.last_message_type as "lastMessageType",
      c.last_message_at as "lastMessageTime",
      (
        SELECT COUNT(*)::int 
        FROM messages 
        WHERE conversation_id = c.id 
          AND receiver_id = ${adminId} 
          AND is_read = false
      ) as "unreadCount"
    FROM conversations c
    JOIN users u ON (
      (u.id = c.participant1 AND c.participant2 = ${adminId})
      OR (u.id = c.participant2 AND c.participant1 = ${adminId})
    )
    ORDER BY c.id, c.last_message_at DESC NULLS LAST
  `);

    return result.rows;
  }

  async getUserConversations(userId: string) {
    const result = await this.drizzle.db.execute(sql`
      SELECT DISTINCT ON (c.id)
        c.id as "conversationId",
        u.id as "userId",
        u.name,
        u.profile_image as "profileImage",
        COALESCE(u.is_online, false) as "isOnline",
        u.last_seen as "lastSeen",
        c.last_message as "lastMessage",
        c.last_message_type as "lastMessageType",
        c.last_message_at as "lastMessageTime",
        (
          SELECT COUNT(*)::int 
          FROM messages 
          WHERE conversation_id = c.id 
            AND receiver_id = ${userId} 
            AND is_read = false
        ) as "unreadCount"
      FROM conversations c
      JOIN users u ON (
        (u.id = c.participant1 AND c.participant2 = ${userId})
        OR (u.id = c.participant2 AND c.participant1 = ${userId})
      )
      WHERE u.id != ${userId} AND u.is_admin = true
      ORDER BY c.id, c.last_message_at DESC NULLS LAST
    `);

    return result.rows;
  }

  // ==========================================
  // USER STATUS
  // ==========================================

  async updateUserStatus(userId: string, isOnline: boolean): Promise<void> {
    await this.drizzle.withRetry(async (db) => {
      const updateData: Record<string, unknown> = {
        isOnline,
        updatedAt: new Date(),
      };

      if (isOnline) {
        updateData.lastSeen = null;
      } else {
        updateData.lastSeen = new Date();
      }

      try {
        await db.update(users).set(updateData).where(eq(users.id, userId));
      } catch (error: unknown) {
        if (
          error instanceof Error &&
          error.message?.includes('Connection terminated')
        ) {
          console.warn(
            `⚠️ Could not update status for ${userId}: connection lost`,
          );
          return;
        }
        throw error;
      }
    });
  }

  async resetAllOnlineStatuses() {
    try {
      await this.drizzle.db
        .update(users)
        .set({ isOnline: false, lastSeen: new Date() })
        .where(eq(users.isOnline, true));
      console.log('🔄 Reset all stale online statuses on server startup');
    } catch (error) {
      console.error('Failed to reset online statuses:', error);
    }
  }

  // ==========================================
  // DEVICE TOKENS
  // ==========================================

  async registerDeviceToken(userId: string, token: string, platform: string) {
    const [existing] = await this.drizzle.db
      .select()
      .from(deviceTokens)
      .where(eq(deviceTokens.token, token))
      .limit(1);

    if (existing) {
      await this.drizzle.db
        .update(deviceTokens)
        .set({ userId, platform, isActive: true, updatedAt: new Date() })
        .where(eq(deviceTokens.id, existing.id));
    } else {
      await this.drizzle.db.insert(deviceTokens).values({
        id: uuidv4(),
        userId,
        token,
        platform,
        isActive: true,
      });
    }
  }

  async unregisterDeviceToken(userId: string, token: string) {
    await this.drizzle.db
      .update(deviceTokens)
      .set({ isActive: false, updatedAt: new Date() })
      .where(
        and(eq(deviceTokens.userId, userId), eq(deviceTokens.token, token)),
      );
  }

  async getUserDeviceTokens(userId: string): Promise<string[]> {
    const tokens = await this.drizzle.db
      .select({ token: deviceTokens.token })
      .from(deviceTokens)
      .where(
        and(eq(deviceTokens.userId, userId), eq(deviceTokens.isActive, true)),
      );
    return tokens.map((t) => t.token);
  }

  // ==========================================
  // SEARCH FUNCTIONALITY
  // ==========================================

  async searchUsers(
    query: string,
    options?: {
      limit?: number;
      offset?: number;
      role?: 'user' | 'admin';
      excludeIds?: string[];
      isOnline?: boolean;
    },
  ) {
    const {
      limit = 20,
      offset = 0,
      role,
      excludeIds = [],
      isOnline,
    } = options || {};

    const conditions: SQL[] = []; // ✅ Use SQL[] instead of any[]

    if (query && query.trim()) {
      const searchPattern = `%${query.trim()}%`;
      conditions.push(
        or(
          ilike(users.name, searchPattern),
          ilike(users.phoneNumber, searchPattern),
          ilike(users.email, searchPattern),
        )!,
      );
    }

    if (role === 'admin') {
      conditions.push(eq(users.isAdmin, true));
    } else if (role === 'user') {
      conditions.push(eq(users.isAdmin, false));
    }

    if (excludeIds.length > 0) {
      conditions.push(sql`${users.id} NOT IN (${sql.join(excludeIds)})`);
    }

    if (isOnline !== undefined) {
      conditions.push(eq(users.isOnline, isOnline));
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    const [usersList, countResult] = await Promise.all([
      this.drizzle.db
        .select({
          id: users.id,
          name: users.name,
          phoneNumber: users.phoneNumber,
          email: users.email,
          profileImage: users.profileImage,
          isOnline: users.isOnline,
          lastSeen: users.lastSeen,
          isAdmin: users.isAdmin,
          marketId: users.marketId,
          createdAt: users.createdAt,
        })
        .from(users)
        .where(whereClause)
        .orderBy(desc(users.isOnline), asc(users.name))
        .limit(Math.min(limit, 100))
        .offset(offset),

      this.drizzle.db
        .select({ count: sql<number>`count(*)::int` })
        .from(users)
        .where(whereClause),
    ]);

    return {
      data: usersList,
      total: countResult[0]?.count || 0,
      limit: Math.min(limit, 100),
      offset,
    };
  }

  async searchChatUsers(
    currentUserId: string,
    query: string,
    limit: number = 20,
  ) {
    const currentUser = await this.getUserById(currentUserId);
    if (!currentUser) {
      throw new NotFoundException('User not found');
    }

    const searchPattern = `%${query.trim()}%`;
    const conditions: SQL[] = []; // ✅ Use SQL[] instead of any[]

    conditions.push(sql`${users.id} != ${currentUserId}`);

    if (!currentUser.isAdmin) {
      conditions.push(eq(users.isAdmin, true));
    }

    if (query && query.trim()) {
      conditions.push(
        or(
          ilike(users.name, searchPattern),
          ilike(users.phoneNumber, searchPattern),
        )!,
      );
    }

    return this.drizzle.db
      .select({
        id: users.id,
        name: users.name,
        phoneNumber: users.phoneNumber,
        profileImage: users.profileImage,
        isOnline: users.isOnline,
        lastSeen: users.lastSeen,
        isAdmin: users.isAdmin,
      })
      .from(users)
      .where(and(...conditions))
      .orderBy(desc(users.isOnline), asc(users.name))
      .limit(Math.min(limit, 50));
  }

  async searchConversations(userId: string, query: string, limit: number = 20) {
    const searchPattern = `%${query.trim()}%`;

    const result = await this.drizzle.db.execute(sql`
    SELECT DISTINCT ON (c.id)
      c.id as "conversationId",
      u.id as "userId",
      u.name,
      u.phone_number as "phoneNumber",
      u.profile_image as "profileImage",
      u.is_online as "isOnline",
      u.last_seen as "lastSeen",
      c.last_message as "lastMessage",
      c.last_message_type as "lastMessageType",
      c.last_message_at as "lastMessageTime",
      (
        SELECT COUNT(*)::int 
        FROM messages 
        WHERE conversation_id = c.id 
          AND receiver_id = ${userId} 
          AND is_read = false
      ) as "unreadCount"
    FROM conversations c
    JOIN users u ON (
      (u.id = c.participant1 AND c.participant2 = ${userId})
      OR (u.id = c.participant2 AND c.participant1 = ${userId})
    )
    WHERE 
      u.id != ${userId}
      AND (
        u.name ILIKE ${searchPattern}
        OR u.phone_number ILIKE ${searchPattern}
        OR c.last_message ILIKE ${searchPattern}
      )
    ORDER BY c.id, c.last_message_at DESC NULLS LAST
    LIMIT ${Math.min(limit, 50)}
  `);

    return result.rows;
  }
}
