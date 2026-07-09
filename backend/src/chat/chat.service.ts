import {
  Injectable,
  ForbiddenException,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { eq, and, or, desc, sql, asc, inArray, ilike, SQL } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';
import {
  messages,
  users,
  conversations,
  deviceTokens,
} from '../drizzle/schema';

@Injectable()
export class ChatService {
  private readonly logger = new Logger(ChatService.name);

  // Simple in-memory cache (replaces Redis)
  private readonly memoryCache = new Map<
    string,
    { data: any; expiry: number }
  >();

  constructor(private readonly drizzle: DrizzleService) {}

  // ==========================================
  // IN-MEMORY CACHE HELPERS
  // ==========================================

  private getFromCache<T>(key: string): T | null {
    const item = this.memoryCache.get(key);
    if (!item) return null;

    if (Date.now() > item.expiry) {
      this.memoryCache.delete(key);
      return null;
    }

    return item.data as T;
  }

  private setInCache(key: string, data: any, ttlSeconds: number): void {
    this.memoryCache.set(key, {
      data,
      expiry: Date.now() + ttlSeconds * 1000,
    });
  }

  private deleteFromCache(key: string): void {
    this.memoryCache.delete(key);
  }

  private clearCachePattern(pattern: string): void {
    for (const key of this.memoryCache.keys()) {
      if (key.includes(pattern)) {
        this.memoryCache.delete(key);
      }
    }
  }

  // ==========================================
  // CACHE TTL CONSTANTS
  // ==========================================

  private readonly CACHE_TTL = {
    USER: 300,
    CONVERSATION: 5,
    PERMISSION: 300,
    UNREAD_COUNT: 120,
    ADMIN_LIST: 60,
    CONVERSATION_EXISTS: 3600,
  };

  // ==========================================
  // HELPER: Convert Date to ISO string safely
  // ==========================================
  private toISOString(value: any): string | null {
    if (value instanceof Date) {
      return value.toISOString();
    }
    if (typeof value === 'string') {
      try {
        return new Date(value).toISOString();
      } catch {
        return value;
      }
    }
    return value ?? null;
  }

  // ==========================================
  // OPTIMIZED USER QUERIES WITH CACHING
  // ==========================================

  async getUserById(userId: string, options: { forceRefresh?: boolean } = {}) {
    const cacheKey = `user:${userId}`;

    if (!options.forceRefresh) {
      const cached = this.getFromCache<any>(cacheKey);
      if (cached) {
        this.logger.debug(`Cache hit: ${cacheKey}`);
        return cached;
      }
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

    if (user) {
      const userWithISO = {
        ...user,
        lastSeen: this.toISOString(user.lastSeen),
      };

      this.setInCache(cacheKey, userWithISO, this.CACHE_TTL.USER);
      return userWithISO;
    }

    return user || null;
  }

  async getAvailableAdmins() {
    const cacheKey = 'admins:available';

    const cached = this.getFromCache<any[]>(cacheKey);
    if (cached) {
      return cached;
    }

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

    const adminsWithISO = admins.map((admin) => ({
      ...admin,
      lastSeen: this.toISOString(admin.lastSeen),
    }));

    this.setInCache(cacheKey, adminsWithISO, this.CACHE_TTL.ADMIN_LIST);
    return adminsWithISO;
  }

  async getAdminUsersForChat(userId: string) {
    const currentUser = await this.getUserById(userId);
    if (!currentUser) {
      throw new NotFoundException('User not found');
    }

    const admins = await this.getAvailableAdmins();
    return admins.filter((admin) => admin.id !== userId);
  }

  // ==========================================
  // OPTIMIZED CONVERSATION MANAGEMENT
  // ==========================================

  async getOrCreateConversation(userId1: string, userId2: string) {
    const [p1, p2] = [userId1, userId2].sort();
    const cacheKey = `conv:exists:${p1}:${p2}`;

    // Check cache first
    const cached = this.getFromCache<any>(cacheKey);
    if (cached) {
      this.logger.debug(`Cache hit for conversation: ${cacheKey}`);
      return cached;
    }

    // Try to find existing conversation
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

    if (existing) {
      const conversationWithISO = {
        ...existing,
        lastMessageAt: this.toISOString(existing.lastMessageAt),
        createdAt: this.toISOString(existing.createdAt),
        updatedAt: this.toISOString(existing.updatedAt),
      };

      this.setInCache(
        cacheKey,
        conversationWithISO,
        this.CACHE_TTL.CONVERSATION_EXISTS,
      );
      return conversationWithISO;
    }

    // Create new conversation
    try {
      const [conversation] = await this.drizzle.db
        .insert(conversations)
        .values({
          id: uuidv4(),
          participant1: p1,
          participant2: p2,
        })
        .returning();

      const conversationWithISO = {
        ...conversation,
        lastMessageAt: this.toISOString(conversation.lastMessageAt),
        createdAt: this.toISOString(conversation.createdAt),
        updatedAt: this.toISOString(conversation.updatedAt),
      };

      this.setInCache(
        cacheKey,
        conversationWithISO,
        this.CACHE_TTL.CONVERSATION_EXISTS,
      );
      this.logger.log(`Created new conversation: ${conversation.id}`);
      return conversationWithISO;
    } catch (error) {
      this.logger.warn(`Insert failed, retrying find: ${error}`);

      const [retryExisting] = await this.drizzle.db
        .select()
        .from(conversations)
        .where(
          and(
            eq(conversations.participant1, p1),
            eq(conversations.participant2, p2),
          ),
        )
        .limit(1);

      if (retryExisting) {
        return {
          ...retryExisting,
          lastMessageAt: this.toISOString(retryExisting.lastMessageAt),
          createdAt: this.toISOString(retryExisting.createdAt),
          updatedAt: this.toISOString(retryExisting.updatedAt),
        };
      }

      throw error;
    }
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
  ) {
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

    // Update conversation metadata
    await this.drizzle.db
      .update(conversations)
      .set({
        lastMessage: preview,
        lastMessageType: type,
        lastMessageAt: now,
        updatedAt: now,
      })
      .where(eq(conversations.id, conversation.id));

    // Invalidate caches
    this.invalidateConversationCache(senderId, receiverId);

    this.logger.log(`✅ Message sent: ${senderId} → ${receiverId}`);

    return {
      ...message,
      createdAt: this.toISOString(message.createdAt),
      updatedAt: this.toISOString(message.updatedAt),
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

  async validateMessagePermission(senderId: string, receiverId: string) {
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

    if (sender.isAdmin || sender.isSuperAdmin) {
      return;
    }

    if (!receiver.isAdmin && !receiver.isSuperAdmin) {
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

    const result = await this.drizzle.db
      .select()
      .from(messages)
      .where(and(...conditions))
      .orderBy(desc(messages.createdAt))
      .limit(Math.min(limit, 100));

    this.logger.debug(
      `Fetched ${result.length} messages for conversation ${conversation.id}`,
    );

    return result.map((message) => ({
      ...message,
      createdAt: this.toISOString(message.createdAt),
      updatedAt: this.toISOString(message.updatedAt),
      readAt: this.toISOString(message.readAt),
    }));
  }

  private async validateMessageAccess(userId: string, partnerId: string) {
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

  async markAsRead(userId: string, partnerId: string) {
    const conversation = await this.getOrCreateConversation(userId, partnerId);
    const now = new Date();

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
          eq(messages.receiverId, userId),
          eq(messages.isRead, false),
        ),
      )
      .returning({ id: messages.id });

    const count = result.length;
    this.logger.log(`✅ Marked ${count} messages as read for user ${userId}`);

    return {
      count,
      conversationId: conversation.id,
      readAt: now.toISOString(),
    };
  }

  // ==========================================
  // UNREAD COUNT MANAGEMENT (DATABASE-BASED)
  // ==========================================

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
    const cacheKey = `conv:admin:${adminId}`;

    const cached = this.getFromCache<any[]>(cacheKey);
    if (cached) {
      return cached;
    }

    const result = await this.drizzle.db.execute(sql`
      SELECT DISTINCT ON (c.id)
        c.id as "conversationId",
        u.id as "userId",
        u.name,
        u.phone_number as "phoneNumber",
        u.profile_image as "profileImage",
        COALESCE(u.is_online, false) as "isOnline",
        u.last_seen as "lastSeen",
        c.last_message as "lastMessage",
        c.last_message_type as "lastMessageType",
        c.last_message_at as "lastMessageTime"
      FROM conversations c
      JOIN users u ON (
        (u.id = c.participant1 AND c.participant2 = ${adminId})
        OR (u.id = c.participant2 AND c.participant1 = ${adminId})
      )
      ORDER BY c.id, c.last_message_at DESC NULLS LAST
    `);

    const rows = result.rows || [];

    // Get unread counts from database
    const unreadCounts = await this.getUnreadCountsForConversations(
      adminId,
      rows.map((r: any) => r.conversationId),
    );

    const enrichedRows = rows.map((row: any) => ({
      ...row,
      lastSeen: this.toISOString(row.lastSeen),
      lastMessageTime: this.toISOString(row.lastMessageTime),
      unreadCount: unreadCounts.get(row.conversationId) || 0,
    }));

    this.setInCache(cacheKey, enrichedRows, this.CACHE_TTL.CONVERSATION);
    return enrichedRows;
  }

  async getUserConversations(userId: string) {
    const cacheKey = `conv:user:${userId}`;

    const cached = this.getFromCache<any[]>(cacheKey);
    if (cached) {
      return cached;
    }

    const result = await this.drizzle.db.execute(sql`
      SELECT DISTINCT ON (c.id)
        c.id as "conversationId",
        u.id as "userId",
        u.name,
        u.phone_number as "phoneNumber",
        u.profile_image as "profileImage",
        COALESCE(u.is_online, false) as "isOnline",
        u.last_seen as "lastSeen",
        c.last_message as "lastMessage",
        c.last_message_type as "lastMessageType",
        c.last_message_at as "lastMessageTime"
      FROM conversations c
      JOIN users u ON (
        (u.id = c.participant1 AND c.participant2 = ${userId})
        OR (u.id = c.participant2 AND c.participant1 = ${userId})
      )
      WHERE u.id != ${userId} 
        AND (u.is_admin = true OR u.is_super_admin = true)
        AND u.is_active = true
      ORDER BY c.id, c.last_message_at DESC NULLS LAST
    `);

    const rows = result.rows || [];

    // Get unread counts from database
    const unreadCounts = await this.getUnreadCountsForConversations(
      userId,
      rows.map((r: any) => r.conversationId),
    );

    const enrichedRows = rows.map((row: any) => ({
      ...row,
      lastSeen: this.toISOString(row.lastSeen),
      lastMessageTime: this.toISOString(row.lastMessageTime),
      unreadCount: unreadCounts.get(row.conversationId) || 0,
    }));

    this.setInCache(cacheKey, enrichedRows, this.CACHE_TTL.CONVERSATION);
    return enrichedRows;
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
      countMap.set(row.conversationId, row.count);
    });

    return countMap;
  }

  // ==========================================
  // CACHE INVALIDATION
  // ==========================================

  private invalidateConversationCache(userId1: string, userId2: string) {
    this.clearCachePattern(`conv:admin:${userId1}`);
    this.clearCachePattern(`conv:admin:${userId2}`);
    this.clearCachePattern(`conv:user:${userId1}`);
    this.clearCachePattern(`conv:user:${userId2}`);
  }

  invalidateUserCache(userId: string) {
    this.deleteFromCache(`user:${userId}`);
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

    this.invalidateUserCache(userId);
  }

  async resetAllOnlineStatuses() {
    try {
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

      // Invalidate cache for all affected users
      result.forEach((u) => this.invalidateUserCache(u.id));

      this.logger.log(`✅ Reset ${result.length} stale online statuses`);
    } catch (error) {
      this.logger.error('Failed to reset online statuses:', error);
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

    this.deleteFromCache(`device_tokens:${userId}`);
    this.logger.log(`📱 Device token registered for user ${userId}`);
  }

  async unregisterDeviceToken(userId: string, token: string) {
    const now = new Date();

    await this.drizzle.db
      .update(deviceTokens)
      .set({ isActive: false, updatedAt: now })
      .where(
        and(eq(deviceTokens.userId, userId), eq(deviceTokens.token, token)),
      );

    this.deleteFromCache(`device_tokens:${userId}`);
    this.logger.log(`📱 Device token unregistered for user ${userId}`);
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

    const conditions: SQL[] = [];
    conditions.push(eq(users.isActive, true));

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
        sql`(${users.isAdmin} = true OR ${users.isSuperAdmin} = true)`,
      );
    } else if (role === 'user') {
      conditions.push(
        sql`(${users.isAdmin} = false AND ${users.isSuperAdmin} = false)`,
      );
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

    const usersWithISO = usersList.map((user) => ({
      ...user,
      lastSeen: this.toISOString(user.lastSeen),
      createdAt: this.toISOString(user.createdAt),
    }));

    return {
      data: usersWithISO,
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
    const conditions: SQL[] = [];

    conditions.push(sql`${users.id} != ${currentUserId}`);
    conditions.push(eq(users.isActive, true));

    if (!currentUser.isAdmin && !currentUser.isSuperAdmin) {
      conditions.push(
        sql`(${users.isAdmin} = true OR ${users.isSuperAdmin} = true)`,
      );
    }

    if (query && query.trim()) {
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
      lastSeen: this.toISOString(user.lastSeen),
    }));
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
        COALESCE(u.is_online, false) as "isOnline",
        u.last_seen as "lastSeen",
        c.last_message as "lastMessage",
        c.last_message_type as "lastMessageType",
        c.last_message_at as "lastMessageTime"
      FROM conversations c
      JOIN users u ON (
        (u.id = c.participant1 AND c.participant2 = ${userId})
        OR (u.id = c.participant2 AND c.participant1 = ${userId})
      )
      WHERE 
        u.id != ${userId}
        AND u.is_active = true
        AND (
          u.name ILIKE ${searchPattern}
          OR u.phone_number ILIKE ${searchPattern}
          OR c.last_message ILIKE ${searchPattern}
        )
      ORDER BY c.id, c.last_message_at DESC NULLS LAST
      LIMIT ${Math.min(limit, 50)}
    `);

    const rows = result.rows || [];

    // Get unread counts
    const unreadCounts = await this.getUnreadCountsForConversations(
      userId,
      rows.map((r: any) => r.conversationId),
    );

    return rows.map((row: any) => ({
      ...row,
      lastSeen: this.toISOString(row.lastSeen),
      lastMessageTime: this.toISOString(row.lastMessageTime),
      unreadCount: unreadCounts.get(row.conversationId) || 0,
    }));
  }
}
