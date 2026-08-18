import {
  Injectable,
  ForbiddenException,
  NotFoundException,
  BadRequestException,
  Logger,
  Inject,
} from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { eq, and, or, desc, sql, asc, inArray, ilike, SQL } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';
import { Redis } from '@upstash/redis';
import {
  messages,
  users,
  conversations,
  deviceTokens,
} from '../drizzle/schema';

// Export interfaces so controller can use them
export interface UserBasic {
  id: string;
  name: string | null;
  phoneNumber: string | null;
  email: string | null;
  profileImage: string | null;
  isOnline: boolean;
  lastSeen: string | null;
  isAdmin: boolean;
  isSuperAdmin: boolean;
  isActive: boolean;
  marketId: string | null;
}

export interface ConversationWithParticipants {
  conversationId: string;
  userId: string;
  name: string | null;
  phoneNumber: string | null;
  profileImage: string | null;
  isOnline: boolean;
  lastSeen: string | null;
  lastMessage: string | null;
  lastMessageType: string | null;
  lastMessageTime: string | null;
  unreadCount: number;
}

export interface MessageResult {
  id: string;
  conversationId: string;
  senderId: string;
  receiverId: string;
  content: string | null;
  type: string;
  mediaUrl: string | null;
  isRead: boolean;
  createdAt: string;
  updatedAt: string;
  readAt: string | null;
}

@Injectable()
export class ChatService {
  private readonly logger = new Logger(ChatService.name);

  private readonly CACHE_TTL = {
    USER: 300,
    CONVERSATION: 30,
    PERMISSION: 300,
    UNREAD_COUNT: 60,
    ADMIN_LIST: 60,
    MESSAGES: 30,
  };

  constructor(
    private readonly drizzle: DrizzleService,
    @Inject('REDIS_CLIENT') private readonly redis: Redis,
  ) {}

  // ==========================================
  // REDIS CACHE HELPERS
  // ==========================================

  private async getFromCache<T>(key: string): Promise<T | null> {
    try {
      const data = await this.redis.get(key);
      if (!data) return null;
      return typeof data === 'string' ? JSON.parse(data) : (data as T);
    } catch (error) {
      this.logger.warn(`Redis get failed for ${key}: ${error}`);
      return null;
    }
  }

  private async setInCache(
    key: string,
    data: unknown,
    ttlSeconds: number,
  ): Promise<void> {
    try {
      await this.redis.set(key, JSON.stringify(data), { ex: ttlSeconds });
    } catch (error) {
      this.logger.warn(`Redis set failed for ${key}: ${error}`);
    }
  }

  private async deleteFromCache(key: string): Promise<void> {
    try {
      await this.redis.del(key);
    } catch (error) {
      this.logger.warn(`Redis delete failed for ${key}: ${error}`);
    }
  }

  private async clearCachePattern(pattern: string): Promise<void> {
    try {
      const keys = await this.redis.keys(`*${pattern}*`);
      if (keys.length > 0) {
        await this.redis.del(...keys);
      }
    } catch (error) {
      this.logger.warn(`Redis clear pattern failed for ${pattern}: ${error}`);
    }
  }

  // ==========================================
  // HELPER: Convert Date to ISO string safely
  // ==========================================

  private toISOString(value: Date | string | null): string | null {
    if (!value) return null;
    if (value instanceof Date) return value.toISOString();
    try {
      return new Date(value).toISOString();
    } catch {
      return value;
    }
  }

  // ==========================================
  // USER QUERIES WITH REDIS CACHING
  // ==========================================

  async getUserById(
    userId: string,
    options: { forceRefresh?: boolean } = {},
  ): Promise<UserBasic | null> {
    const cacheKey = `user:${userId}`;

    if (!options.forceRefresh) {
      const cached = await this.getFromCache<UserBasic>(cacheKey);
      if (cached) return cached;
    }

    const [user] = await this.drizzle.db
      .select({
        id: users.id,
        name: users.name,
        phoneNumber: users.phoneNumber,
        email: users.email,
        profileImage: users.profileImage,
        isOnline: users.isOnline,
        lastSeen: users.lastSeen,
        isAdmin: users.isAdmin,
        isSuperAdmin: users.isSuperAdmin,
        isActive: users.isActive,
        marketId: users.marketId,
      })
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) return null;

    const userWithISO: UserBasic = {
      id: user.id,
      name: user.name,
      phoneNumber: user.phoneNumber,
      email: user.email,
      profileImage: user.profileImage,
      isOnline: user.isOnline ?? false,
      lastSeen: this.toISOString(user.lastSeen),
      isAdmin: user.isAdmin ?? false,
      isSuperAdmin: user.isSuperAdmin ?? false,
      isActive: user.isActive ?? true,
      marketId: user.marketId,
    };

    await this.setInCache(cacheKey, userWithISO, this.CACHE_TTL.USER);
    return userWithISO;
  }

  async invalidateUserCache(userId: string): Promise<void> {
    await this.deleteFromCache(`user:${userId}`);
  }

  // ==========================================
  // CONVERSATION PARTNERS
  // ==========================================

  async getConversationPartnerIds(userId: string): Promise<string[]> {
    const result = await this.drizzle.db
      .select({
        participant1: conversations.participant1,
        participant2: conversations.participant2,
      })
      .from(conversations)
      .where(
        or(
          eq(conversations.participant1, userId),
          eq(conversations.participant2, userId),
        ),
      );

    const partnerIds: string[] = [];
    for (const conv of result) {
      const partnerId =
        conv.participant1 === userId ? conv.participant2 : conv.participant1;
      if (partnerId) partnerIds.push(partnerId);
    }
    return partnerIds;
  }

  // ==========================================
  // ADMIN QUERIES
  // ==========================================

  async getAvailableAdmins(): Promise<UserBasic[]> {
    const cacheKey = 'admins:available';

    const cached = await this.getFromCache<UserBasic[]>(cacheKey);
    if (cached) return cached;

    const admins = await this.drizzle.db
      .select({
        id: users.id,
        name: users.name,
        phoneNumber: users.phoneNumber,
        email: users.email,
        profileImage: users.profileImage,
        isOnline: users.isOnline,
        lastSeen: users.lastSeen,
        isAdmin: users.isAdmin,
        isSuperAdmin: users.isSuperAdmin,
        isActive: users.isActive,
        marketId: users.marketId,
      })
      .from(users)
      .where(
        and(
          eq(users.isActive, true),
          or(eq(users.isAdmin, true), eq(users.isSuperAdmin, true)),
        ),
      )
      .orderBy(desc(users.isSuperAdmin), desc(users.isOnline), asc(users.name))
      .limit(20);

    const adminsWithISO: UserBasic[] = admins.map((admin) => ({
      id: admin.id,
      name: admin.name,
      phoneNumber: admin.phoneNumber,
      email: admin.email,
      profileImage: admin.profileImage,
      isOnline: admin.isOnline ?? false,
      lastSeen: this.toISOString(admin.lastSeen),
      isAdmin: admin.isAdmin ?? false,
      isSuperAdmin: admin.isSuperAdmin ?? false,
      isActive: admin.isActive ?? true,
      marketId: admin.marketId,
    }));

    await this.setInCache(cacheKey, adminsWithISO, this.CACHE_TTL.ADMIN_LIST);
    return adminsWithISO;
  }

  async getAdminUsersForChat(userId: string): Promise<UserBasic[]> {
    const currentUser = await this.getUserById(userId);
    if (!currentUser) {
      throw new NotFoundException('User not found');
    }

    const admins = await this.getAvailableAdmins();
    return admins.filter((admin) => admin.id !== userId);
  }

  // ==========================================
  // CONVERSATION MANAGEMENT
  // ==========================================

  async getOrCreateConversation(
    userId1: string,
    userId2: string,
  ): Promise<{ id: string; participant1: string; participant2: string }> {
    const [p1, p2] = [userId1, userId2].sort();
    const cacheKey = `conv:exists:${p1}:${p2}`;

    const cached = await this.getFromCache<{
      id: string;
      participant1: string;
      participant2: string;
    }>(cacheKey);
    if (cached) return cached;

    const existingUsers = await this.drizzle.db
      .select({ id: users.id })
      .from(users)
      .where(inArray(users.id, [p1, p2]));

    if (existingUsers.length < 2) {
      throw new NotFoundException(
        'Cannot open conversation: One or both users have been deleted.',
      );
    }

    const [existing] = await this.drizzle.db
      .select({
        id: conversations.id,
        participant1: conversations.participant1,
        participant2: conversations.participant2,
      })
      .from(conversations)
      .where(
        and(
          eq(conversations.participant1, p1),
          eq(conversations.participant2, p2),
        ),
      )
      .limit(1);

    if (existing) {
      await this.setInCache(cacheKey, existing, 3600);
      return existing;
    }

    try {
      const [conversation] = await this.drizzle.db
        .insert(conversations)
        .values({
          id: uuidv4(),
          participant1: p1,
          participant2: p2,
        })
        .returning({
          id: conversations.id,
          participant1: conversations.participant1,
          participant2: conversations.participant2,
        });

      await this.setInCache(cacheKey, conversation, 3600);
      return conversation;
    } catch (error) {
      const [retryExisting] = await this.drizzle.db
        .select({
          id: conversations.id,
          participant1: conversations.participant1,
          participant2: conversations.participant2,
        })
        .from(conversations)
        .where(
          and(
            eq(conversations.participant1, p1),
            eq(conversations.participant2, p2),
          ),
        )
        .limit(1);

      if (retryExisting) {
        await this.setInCache(cacheKey, retryExisting, 3600);
        return retryExisting;
      }

      throw error;
    }
  }

  async createConversation(
    userId1: string,
    userId2: string,
  ): Promise<{ id: string; participant1: string; participant2: string }> {
    await this.validateConversationParticipants(userId1, userId2);
    return this.getOrCreateConversation(userId1, userId2);
  }

  private async validateConversationParticipants(
    userId1: string,
    userId2: string,
  ): Promise<void> {
    if (userId1 === userId2) {
      throw new BadRequestException('Cannot create conversation with yourself');
    }

    const [user1, user2] = await Promise.all([
      this.getUserById(userId1, { forceRefresh: true }),
      this.getUserById(userId2, { forceRefresh: true }),
    ]);

    if (!user1 || !user2) {
      throw new NotFoundException('One or both users not found');
    }

    if (!user1.isActive || !user2.isActive) {
      throw new ForbiddenException('One or both users are inactive');
    }

    if (
      !(user1.isAdmin || user1.isSuperAdmin) &&
      !(user2.isAdmin || user2.isSuperAdmin)
    ) {
      throw new ForbiddenException(
        'Conversations require at least one admin or super admin participant',
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
  ): Promise<MessageResult> {
    await this.validateMessagePermission(senderId, receiverId);

    if (type === 'text' && !content?.trim()) {
      throw new BadRequestException('Message content cannot be empty');
    }

    const conversation = await this.getOrCreateConversation(
      senderId,
      receiverId,
    );

    const now = new Date();

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
        createdAt: now,
        updatedAt: now,
      })
      .returning();

    const preview = this.generateMessagePreview(type, content);

    await this.drizzle.db
      .update(conversations)
      .set({
        lastMessage: preview,
        lastMessageType: type,
        lastMessageAt: now,
        updatedAt: now,
      })
      .where(eq(conversations.id, conversation.id));

    await this.invalidateConversationCache(senderId, receiverId);

    return {
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      receiverId: message.receiverId,
      content: message.content,
      type: message.type,
      mediaUrl: message.mediaUrl,
      isRead: message.isRead ?? false,
      createdAt: this.toISOString(message.createdAt)!,
      updatedAt: this.toISOString(message.updatedAt)!,
      readAt: this.toISOString(message.readAt),
    };
  }

  private generateMessagePreview(type: string, content: string | null): string {
    switch (type) {
      case 'image':
        return '📷 Photo';
      case 'file':
        return '📎 File';
      default:
        return content?.substring(0, 100) || '';
    }
  }

  async validateMessagePermission(
    senderId: string,
    receiverId: string,
  ): Promise<void> {
    const usersData = await this.drizzle.db
      .select({
        id: users.id,
        isAdmin: users.isAdmin,
        isSuperAdmin: users.isSuperAdmin,
        isActive: users.isActive,
      })
      .from(users)
      .where(inArray(users.id, [senderId, receiverId]));

    const sender = usersData.find((u) => u.id === senderId);
    const receiver = usersData.find((u) => u.id === receiverId);

    if (!sender) throw new NotFoundException('Sender not found');
    if (!receiver) throw new NotFoundException('Receiver not found');

    if (!sender.isActive || !receiver.isActive) {
      throw new ForbiddenException('Cannot message inactive user');
    }

    if (sender.isAdmin || sender.isSuperAdmin) return;

    if (!receiver.isAdmin && !receiver.isSuperAdmin) {
      throw new ForbiddenException('You can only message administrators');
    }
  }

  // ==========================================
  // GET MESSAGES
  // ==========================================

  async getMessages(
    userId: string,
    partnerId: string,
    limit: number = 50,
    before?: Date,
  ): Promise<MessageResult[]> {
    await this.validateMessageAccess(userId, partnerId);

    const conversation = await this.getOrCreateConversation(userId, partnerId);
    const cacheKey = `messages:${conversation.id}:${limit}:${before?.toISOString() || 'latest'}`;

    const cached = await this.getFromCache<MessageResult[]>(cacheKey);
    if (cached) return cached;

    const conditions = [eq(messages.conversationId, conversation.id)];
    if (before) {
      conditions.push(sql`${messages.createdAt} < ${before.toISOString()}`);
    }

    const result = await this.drizzle.db
      .select()
      .from(messages)
      .where(and(...conditions))
      .orderBy(desc(messages.createdAt))
      .limit(Math.min(limit, 100));

    const messagesWithISO: MessageResult[] = result.map((message) => ({
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      receiverId: message.receiverId,
      content: message.content,
      type: message.type,
      mediaUrl: message.mediaUrl,
      isRead: message.isRead ?? false,
      createdAt: this.toISOString(message.createdAt)!,
      updatedAt: this.toISOString(message.updatedAt)!,
      readAt: this.toISOString(message.readAt),
    }));

    await this.setInCache(cacheKey, messagesWithISO, this.CACHE_TTL.MESSAGES);
    return messagesWithISO;
  }

  private async validateMessageAccess(
    userId: string,
    partnerId: string,
  ): Promise<void> {
    const [user, partner] = await Promise.all([
      this.getUserById(userId),
      this.getUserById(partnerId),
    ]);

    if (!user) throw new NotFoundException('User not found');

    if (!user.isAdmin && !user.isSuperAdmin) {
      if (!partner?.isAdmin && !partner?.isSuperAdmin) {
        throw new ForbiddenException(
          'You can only view messages with administrators',
        );
      }
    }
  }

  async markAsRead(
    userId: string,
    partnerId: string,
  ): Promise<{ count: number; conversationId: string; readAt: string }> {
    const conversation = await this.getOrCreateConversation(userId, partnerId);
    const now = new Date();

    // ✅ FIXED: Mark messages where the user is the RECEIVER and sender is the partner
    const result = await this.drizzle.db
      .update(messages)
      .set({
        isRead: true,
        readAt: now,
        updatedAt: now,
      })
      .where(
        and(
          eq(messages.conversationId, conversation.id),
          eq(messages.receiverId, userId), // ✅ User is the receiver
          eq(messages.senderId, partnerId), // ✅ Partner is the sender
          eq(messages.isRead, false),
        ),
      )
      .returning({ id: messages.id });

    // Invalidate caches
    await this.clearCachePattern(`messages:${conversation.id}:`);
    await this.invalidateConversationCache(userId, partnerId);

    this.logger.log(
      `✅ Marked ${result.length} messages as read: ${userId} → from ${partnerId}`,
    );

    return {
      count: result.length,
      conversationId: conversation.id,
      readAt: now.toISOString(),
    };
  }

  // ==========================================
  // GET CONVERSATION MESSAGES (For Super Admin)
  // ==========================================

  async getConversationMessages(
    conversationId: string,
    limit: number = 50,
  ): Promise<MessageResult[]> {
    const msgs = await this.drizzle.db
      .select()
      .from(messages)
      .where(eq(messages.conversationId, conversationId))
      .orderBy(desc(messages.createdAt))
      .limit(Math.min(limit, 100));

    return msgs.map((msg) => ({
      id: msg.id,
      conversationId: msg.conversationId,
      senderId: msg.senderId,
      receiverId: msg.receiverId,
      content: msg.content,
      type: msg.type,
      mediaUrl: msg.mediaUrl,
      isRead: msg.isRead ?? false,
      createdAt: this.toISOString(msg.createdAt)!,
      updatedAt: this.toISOString(msg.updatedAt)!,
      readAt: this.toISOString(msg.readAt),
    }));
  }

  // ==========================================
  // UNREAD COUNT
  // ==========================================

  async getUnreadCount(userId: string): Promise<{ unreadCount: number }> {
    const cacheKey = `unread:${userId}`;

    const cached = await this.getFromCache<{ unreadCount: number }>(cacheKey);
    if (cached) return cached;

    const [result] = await this.drizzle.db
      .select({ count: sql<number>`count(*)::int` })
      .from(messages)
      .where(and(eq(messages.receiverId, userId), eq(messages.isRead, false)));

    const unreadCount = Number(result?.count) || 0;
    const data = { unreadCount };

    await this.setInCache(cacheKey, data, this.CACHE_TTL.UNREAD_COUNT);
    return data;
  }

  // ==========================================
  // CONVERSATION LISTING
  // ==========================================

  async getAdminConversations(
    adminId: string,
  ): Promise<ConversationWithParticipants[]> {
    const cacheKey = `conv:admin:${adminId}`;

    const cached =
      await this.getFromCache<ConversationWithParticipants[]>(cacheKey);
    if (cached) return cached;

    const result = await this.drizzle.db
      .select({
        conversationId: conversations.id,
        userId: users.id,
        name: users.name,
        phoneNumber: users.phoneNumber,
        profileImage: users.profileImage,
        isOnline: users.isOnline,
        lastSeen: users.lastSeen,
        lastMessage: conversations.lastMessage,
        lastMessageType: conversations.lastMessageType,
        lastMessageTime: conversations.lastMessageAt,
      })
      .from(conversations)
      .innerJoin(
        users,
        or(
          and(
            eq(users.id, conversations.participant1),
            eq(conversations.participant2, adminId),
          ),
          and(
            eq(users.id, conversations.participant2),
            eq(conversations.participant1, adminId),
          ),
        ),
      )
      .where(
        or(
          eq(conversations.participant1, adminId),
          eq(conversations.participant2, adminId),
        ),
      )
      .orderBy(desc(conversations.lastMessageAt));

    const conversationIds = result.map((r) => r.conversationId);
    const unreadCounts = await this.getUnreadCountsForConversations(
      adminId,
      conversationIds,
    );

    const conversationsList: ConversationWithParticipants[] = result.map(
      (row) => ({
        conversationId: row.conversationId,
        userId: row.userId,
        name: row.name,
        phoneNumber: row.phoneNumber,
        profileImage: row.profileImage,
        isOnline: row.isOnline ?? false,
        lastSeen: this.toISOString(row.lastSeen),
        lastMessage: row.lastMessage,
        lastMessageType: row.lastMessageType,
        lastMessageTime: this.toISOString(row.lastMessageTime),
        unreadCount: unreadCounts.get(row.conversationId) || 0,
      }),
    );

    await this.setInCache(
      cacheKey,
      conversationsList,
      this.CACHE_TTL.CONVERSATION,
    );
    return conversationsList;
  }

  async getUserConversations(
    userId: string,
  ): Promise<ConversationWithParticipants[]> {
    const cacheKey = `conv:user:${userId}`;

    const cached =
      await this.getFromCache<ConversationWithParticipants[]>(cacheKey);
    if (cached) return cached;

    const result = await this.drizzle.db
      .select({
        conversationId: conversations.id,
        userId: users.id,
        name: users.name,
        phoneNumber: users.phoneNumber,
        profileImage: users.profileImage,
        isOnline: users.isOnline,
        lastSeen: users.lastSeen,
        lastMessage: conversations.lastMessage,
        lastMessageType: conversations.lastMessageType,
        lastMessageTime: conversations.lastMessageAt,
      })
      .from(conversations)
      .innerJoin(
        users,
        or(
          and(
            eq(users.id, conversations.participant1),
            eq(conversations.participant2, userId),
          ),
          and(
            eq(users.id, conversations.participant2),
            eq(conversations.participant1, userId),
          ),
        ),
      )
      .where(
        and(
          or(
            eq(conversations.participant1, userId),
            eq(conversations.participant2, userId),
          ),
          or(eq(users.isAdmin, true), eq(users.isSuperAdmin, true)),
          eq(users.isActive, true),
        ),
      )
      .orderBy(desc(conversations.lastMessageAt));

    const conversationIds = result.map((r) => r.conversationId);
    const unreadCounts = await this.getUnreadCountsForConversations(
      userId,
      conversationIds,
    );

    const conversationsList: ConversationWithParticipants[] = result.map(
      (row) => ({
        conversationId: row.conversationId,
        userId: row.userId,
        name: row.name,
        phoneNumber: row.phoneNumber,
        profileImage: row.profileImage,
        isOnline: row.isOnline ?? false,
        lastSeen: this.toISOString(row.lastSeen),
        lastMessage: row.lastMessage,
        lastMessageType: row.lastMessageType,
        lastMessageTime: this.toISOString(row.lastMessageTime),
        unreadCount: unreadCounts.get(row.conversationId) || 0,
      }),
    );

    await this.setInCache(
      cacheKey,
      conversationsList,
      this.CACHE_TTL.CONVERSATION,
    );
    return conversationsList;
  }

  private async getUnreadCountsForConversations(
    userId: string,
    conversationIds: string[],
  ): Promise<Map<string, number>> {
    if (conversationIds.length === 0) return new Map();

    const result = await this.drizzle.db
      .select({
        conversationId: messages.conversationId,
        count: sql<number>`count(*)::int`,
      })
      .from(messages)
      .where(
        and(
          eq(messages.receiverId, userId),
          eq(messages.isRead, false),
          inArray(messages.conversationId, conversationIds),
        ),
      )
      .groupBy(messages.conversationId);

    const countMap = new Map<string, number>();
    result.forEach((row) => {
      countMap.set(row.conversationId, Number(row.count));
    });

    return countMap;
  }

  // ==========================================
  // SUPER ADMIN CONVERSATIONS
  // ==========================================

  async getAllConversationsForSuperAdmin(
    superAdminId: string,
    page: number = 1,
    limit: number = 20,
    search?: string,
  ) {
    const offset = (page - 1) * limit;

    const result = await this.drizzle.db
      .select({
        conversationId: conversations.id,
        participant1: conversations.participant1,
        participant2: conversations.participant2,
        lastMessage: conversations.lastMessage,
        lastMessageType: conversations.lastMessageType,
        lastMessageAt: conversations.lastMessageAt,
        createdAt: conversations.createdAt,
      })
      .from(conversations)
      .orderBy(desc(conversations.lastMessageAt))
      .limit(Math.min(limit, 50))
      .offset(offset);

    const userIds = new Set<string>();
    result.forEach((conv) => {
      userIds.add(conv.participant1);
      userIds.add(conv.participant2);
    });

    const usersList = await this.drizzle.db
      .select({
        id: users.id,
        name: users.name,
        phoneNumber: users.phoneNumber,
        profileImage: users.profileImage,
        isOnline: users.isOnline,
        isAdmin: users.isAdmin,
        isSuperAdmin: users.isSuperAdmin,
        isActive: users.isActive,
      })
      .from(users)
      .where(inArray(users.id, Array.from(userIds)));

    const userMap = new Map(usersList.map((u) => [u.id, u]));

    let conversationsList = result.map((conv) => {
      const user1 = userMap.get(conv.participant1);
      const user2 = userMap.get(conv.participant2);

      const admin = user1?.isAdmin || user1?.isSuperAdmin ? user1 : user2;
      const user = user1?.isAdmin || user1?.isSuperAdmin ? user2 : user1;

      return {
        conversationId: conv.conversationId,
        admin: admin
          ? {
              id: admin.id,
              name: admin.name || 'Unknown Admin',
              phone: admin.phoneNumber || '',
              image: admin.profileImage || null,
              isOnline: admin.isOnline || false,
            }
          : null,
        user: user
          ? {
              id: user.id,
              name: user.name || 'Unknown User',
              phone: user.phoneNumber || '',
              image: user.profileImage || null,
              isOnline: user.isOnline || false,
            }
          : null,
        lastMessage: conv.lastMessage || '',
        lastMessageType: conv.lastMessageType || 'text',
        lastMessageTime: this.toISOString(conv.lastMessageAt),
        createdAt: this.toISOString(conv.createdAt),
      };
    });

    // Apply search filter
    if (search && search.trim().length >= 2) {
      const searchLower = search.toLowerCase();
      conversationsList = conversationsList.filter(
        (conv) =>
          conv.admin?.name?.toLowerCase().includes(searchLower) ||
          conv.admin?.phone?.includes(search.trim()) ||
          conv.user?.name?.toLowerCase().includes(searchLower) ||
          conv.user?.phone?.includes(search.trim()) ||
          conv.lastMessage?.toLowerCase().includes(searchLower),
      );
    }

    return {
      conversations: conversationsList,
      pagination: {
        page,
        limit: Math.min(limit, 50),
        total: conversationsList.length,
        hasMore: conversationsList.length === Math.min(limit, 50),
      },
    };
  }

  async getUsersForAdmin(adminId: string, search?: string) {
    const result = await this.drizzle.db
      .select({
        conversationId: conversations.id,
        participant1: conversations.participant1,
        participant2: conversations.participant2,
        lastMessage: conversations.lastMessage,
        lastMessageType: conversations.lastMessageType,
        lastMessageAt: conversations.lastMessageAt,
      })
      .from(conversations)
      .where(
        or(
          eq(conversations.participant1, adminId),
          eq(conversations.participant2, adminId),
        ),
      )
      .orderBy(desc(conversations.lastMessageAt));

    const userIds = new Set<string>();
    result.forEach((conv) => {
      if (conv.participant1 !== adminId) userIds.add(conv.participant1);
      if (conv.participant2 !== adminId) userIds.add(conv.participant2);
    });

    let usersList = await this.drizzle.db
      .select({
        id: users.id,
        name: users.name,
        phoneNumber: users.phoneNumber,
        profileImage: users.profileImage,
        isOnline: users.isOnline,
      })
      .from(users)
      .where(inArray(users.id, Array.from(userIds)));

    if (search && search.trim().length >= 2) {
      const searchLower = search.toLowerCase();
      usersList = usersList.filter(
        (u) =>
          (u.name && u.name.toLowerCase().includes(searchLower)) ||
          (u.phoneNumber && u.phoneNumber.includes(search.trim())),
      );
    }

    const userMap = new Map(usersList.map((u) => [u.id, u]));
    const convMap = new Map<string, (typeof result)[0]>();

    result.forEach((conv) => {
      const otherId =
        conv.participant1 !== adminId ? conv.participant1 : conv.participant2;
      convMap.set(otherId, conv);
    });

    return usersList.map((user) => {
      const conv = convMap.get(user.id);
      return {
        conversationId: conv?.conversationId || null,
        userId: user.id,
        userName: user.name || 'Unknown',
        userPhone: user.phoneNumber || '',
        userImage: user.profileImage || null,
        isOnline: user.isOnline || false,
        lastMessage: conv?.lastMessage || '',
        lastMessageType: conv?.lastMessageType || 'text',
        lastMessageTime: this.toISOString(conv?.lastMessageAt || null),
      };
    });
  }

  // ==========================================
  // CACHE INVALIDATION
  // ==========================================

  private async invalidateConversationCache(
    userId1: string,
    userId2: string,
  ): Promise<void> {
    await this.clearCachePattern(`conv:admin:${userId1}`);
    await this.clearCachePattern(`conv:admin:${userId2}`);
    await this.clearCachePattern(`conv:user:${userId1}`);
    await this.clearCachePattern(`conv:user:${userId2}`);
    await this.clearCachePattern(`unread:${userId1}`);
    await this.clearCachePattern(`unread:${userId2}`);
  }

  // ==========================================
  // USER STATUS MANAGEMENT
  // ==========================================

  async updateUserStatus(userId: string, isOnline: boolean): Promise<void> {
    const now = new Date();

    await this.drizzle.db
      .update(users)
      .set({
        isOnline,
        lastSeen: isOnline ? null : now,
        updatedAt: now,
      })
      .where(eq(users.id, userId));

    await this.invalidateUserCache(userId);
  }

  async resetAllOnlineStatuses(): Promise<void> {
    const now = new Date();

    const result = await this.drizzle.db
      .update(users)
      .set({
        isOnline: false,
        lastSeen: now,
        updatedAt: now,
      })
      .where(eq(users.isOnline, true))
      .returning({ id: users.id });

    for (const user of result) {
      await this.invalidateUserCache(user.id);
    }

    this.logger.log(`✅ Reset ${result.length} stale online statuses`);
  }

  // ==========================================
  // DEVICE TOKENS
  // ==========================================

  async registerDeviceToken(
    userId: string,
    token: string,
    platform: string,
  ): Promise<void> {
    const [existing] = await this.drizzle.db
      .select()
      .from(deviceTokens)
      .where(eq(deviceTokens.token, token))
      .limit(1);

    const now = new Date();

    if (existing) {
      await this.drizzle.db
        .update(deviceTokens)
        .set({ userId, platform, isActive: true, updatedAt: now })
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

    await this.deleteFromCache(`device_tokens:${userId}`);
  }

  async unregisterDeviceToken(userId: string, token: string): Promise<void> {
    const now = new Date();

    await this.drizzle.db
      .update(deviceTokens)
      .set({ isActive: false, updatedAt: now })
      .where(
        and(eq(deviceTokens.userId, userId), eq(deviceTokens.token, token)),
      );

    await this.deleteFromCache(`device_tokens:${userId}`);
  }

  async getUserDeviceTokens(userId: string): Promise<string[]> {
    const cacheKey = `device_tokens:${userId}`;

    const cached = await this.getFromCache<string[]>(cacheKey);
    if (cached) return cached;

    const tokens = await this.drizzle.db
      .select({ token: deviceTokens.token })
      .from(deviceTokens)
      .where(
        and(eq(deviceTokens.userId, userId), eq(deviceTokens.isActive, true)),
      );

    const tokenList = tokens
      .map((t) => t.token)
      .filter((t): t is string => Boolean(t));

    await this.setInCache(cacheKey, tokenList, 300);
    return tokenList;
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

    const conditions: SQL[] = [eq(users.isActive, true)];

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
      conditions.push(
        or(eq(users.isAdmin, true), eq(users.isSuperAdmin, true))!,
      );
    } else if (role === 'user') {
      conditions.push(
        and(eq(users.isAdmin, false), eq(users.isSuperAdmin, false))!,
      );
    }

    if (excludeIds.length > 0) {
      conditions.push(sql`${users.id} NOT IN (${sql.join(excludeIds)})`);
    }

    if (isOnline !== undefined) {
      conditions.push(eq(users.isOnline, isOnline));
    }

    const whereClause = and(...conditions);

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
          isSuperAdmin: users.isSuperAdmin,
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
      data: usersList.map((user) => ({
        ...user,
        isOnline: user.isOnline ?? false,
        isAdmin: user.isAdmin ?? false,
        isSuperAdmin: user.isSuperAdmin ?? false,
        lastSeen: this.toISOString(user.lastSeen),
        createdAt: this.toISOString(user.createdAt),
      })),
      total: Number(countResult[0]?.count) || 0,
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

    const conditions: SQL[] = [
      sql`${users.id} != ${currentUserId}`,
      eq(users.isActive, true),
    ];

    if (!currentUser.isAdmin && !currentUser.isSuperAdmin) {
      conditions.push(
        or(eq(users.isAdmin, true), eq(users.isSuperAdmin, true))!,
      );
    }

    if (query && query.trim()) {
      const searchPattern = `%${query.trim()}%`;
      conditions.push(
        or(
          ilike(users.name, searchPattern),
          ilike(users.phoneNumber, searchPattern),
        )!,
      );
    }

    const usersList = await this.drizzle.db
      .select({
        id: users.id,
        name: users.name,
        phoneNumber: users.phoneNumber,
        email: users.email,
        profileImage: users.profileImage,
        isOnline: users.isOnline,
        lastSeen: users.lastSeen,
        isAdmin: users.isAdmin,
        isSuperAdmin: users.isSuperAdmin,
      })
      .from(users)
      .where(and(...conditions))
      .orderBy(desc(users.isOnline), asc(users.name))
      .limit(Math.min(limit, 50));

    return usersList.map((user) => ({
      ...user,
      isOnline: user.isOnline ?? false,
      isAdmin: user.isAdmin ?? false,
      isSuperAdmin: user.isSuperAdmin ?? false,
      lastSeen: this.toISOString(user.lastSeen),
    }));
  }

  async searchConversations(
    userId: string,
    query: string,
    limit: number = 20,
  ): Promise<ConversationWithParticipants[]> {
    const conversations = await this.getUserConversations(userId);
    const searchLower = query.toLowerCase();

    return conversations
      .filter(
        (conv) =>
          (conv.name && conv.name.toLowerCase().includes(searchLower)) ||
          (conv.phoneNumber && conv.phoneNumber.includes(query)) ||
          (conv.lastMessage &&
            conv.lastMessage.toLowerCase().includes(searchLower)),
      )
      .slice(0, Math.min(limit, 50));
  }
}
