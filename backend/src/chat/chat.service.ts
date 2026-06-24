import { Injectable, ForbiddenException } from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { messages, users, conversations } from '../drizzle/schema';
import { eq, and, or, desc, sql } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class ChatService {
  constructor(private drizzle: DrizzleService) {}

  // ✅ NEW: Get or create a conversation room
  async getOrCreateConversation(userId1: string, userId2: string) {
    // Ensure consistent ordering - smaller ID first
    const [participant1, participant2] = [userId1, userId2].sort();

    // Check if conversation already exists
    const existing = await this.drizzle.db
      .select()
      .from(conversations)
      .where(
        and(
          eq(conversations.participant1, participant1),
          eq(conversations.participant2, participant2),
        ),
      )
      .limit(1);

    if (existing.length > 0) {
      return existing[0];
    }

    // Create new conversation
    const [newConversation] = await this.drizzle.db
      .insert(conversations)
      .values({
        id: uuidv4(),
        participant1,
        participant2,
        createdAt: new Date(),
        updatedAt: new Date(),
      })
      .returning();

    return newConversation;
  }

  // ✅ UPDATED: Save message with conversation ID
  async saveMessage(
    senderId: string,
    receiverId: string,
    content: string,
    type: string,
    mediaUrl?: string,
  ) {
    // Get or create conversation first
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
        content,
        type,
        mediaUrl,
        createdAt: new Date(),
      })
      .returning();

    // Update conversation's last message time
    await this.drizzle.db
      .update(conversations)
      .set({
        lastMessageAt: new Date(),
        lastMessage: content?.substring(0, 100) || '📷 Photo',
        updatedAt: new Date(),
      })
      .where(eq(conversations.id, conversation.id));

    return message;
  }

  // ✅ UPDATED: Get chat history using conversation
  async getChatHistory(userId1: string, userId2: string, limit = 50) {
    // Get the conversation first
    const conversation = await this.getOrCreateConversation(userId1, userId2);

    return this.drizzle.db
      .select()
      .from(messages)
      .where(eq(messages.conversationId, conversation.id))
      .orderBy(desc(messages.createdAt))
      .limit(limit);
  }

  // ... rest of your existing methods remain the same ...

  async validateMessagePermission(
    senderId: string,
    receiverId: string,
    senderIsAdmin: boolean,
  ) {
    if (!senderIsAdmin) {
      const [receiver] = await this.drizzle.db
        .select({ isAdmin: users.isAdmin })
        .from(users)
        .where(eq(users.id, receiverId))
        .limit(1);

      if (!receiver || !receiver.isAdmin) {
        throw new ForbiddenException('Users can only send messages to Admins.');
      }
    }
  }

  async markAsRead(userId: string, chatPartnerId: string) {
    const conversation = await this.getOrCreateConversation(
      userId,
      chatPartnerId,
    );

    const result = await this.drizzle.db
      .update(messages)
      .set({ isRead: true })
      .where(
        and(
          eq(messages.conversationId, conversation.id),
          eq(messages.receiverId, userId),
          eq(messages.isRead, false),
        ),
      )
      .returning();

    return {
      message: 'Messages marked as read',
      count: result.length,
    };
  }

  async getAdminConversations(adminId: string) {
    try {
      const result = await this.drizzle.db.execute(sql`
        SELECT DISTINCT ON (c.id)
          c.id as conversation_id,
          u.id as user_id,
          u.name, 
          u.phone_number, 
          u.profile_image, 
          COALESCE(u.is_online, false) as is_online, 
          u.last_seen,
          c.last_message,
          c.last_message_type,
          c.last_message_at as last_message_time,
          (SELECT COUNT(*) FROM messages 
           WHERE conversation_id = c.id 
           AND receiver_id = ${adminId} 
           AND is_read = false) as unread_count
        FROM conversations c
        JOIN users u ON (u.id = c.participant1 OR u.id = c.participant2)
        WHERE (c.participant1 = ${adminId} OR c.participant2 = ${adminId})
          AND u.id != ${adminId}
        ORDER BY c.id, c.last_message_at DESC
      `);
      return result.rows;
    } catch (error) {
      console.error('Error in getAdminConversations:', error);
      return this.getAdminConversationsFallback(adminId);
    }
  }

  private async getAdminConversationsFallback(adminId: string) {
    const result = await this.drizzle.db.execute(sql`
      SELECT 
        u.id, u.name, u.phone_number, u.profile_image,
        m.content as last_message, 
        m.type as last_message_type, 
        m.created_at as last_message_time,
        (SELECT COUNT(*) FROM messages WHERE sender_id = u.id AND receiver_id = ${adminId} AND is_read = false) as unread_count
      FROM users u
      JOIN messages m ON (m.sender_id = u.id AND m.receiver_id = ${adminId}) OR (m.sender_id = ${adminId} AND m.receiver_id = u.id)
      WHERE u.id != ${adminId}
      GROUP BY u.id, m.content, m.type, m.created_at
      ORDER BY m.created_at DESC
    `);
    return result.rows;
  }

  async getUserConversations(userId: string) {
    try {
      const result = await this.drizzle.db.execute(sql`
        SELECT DISTINCT ON (c.id)
          c.id as conversation_id,
          u.id as user_id,
          u.name, 
          u.profile_image, 
          COALESCE(u.is_online, false) as is_online,
          c.last_message,
          c.last_message_type,
          c.last_message_at as last_message_time,
          (SELECT COUNT(*) FROM messages 
           WHERE conversation_id = c.id 
           AND receiver_id = ${userId} 
           AND is_read = false) as unread_count
        FROM conversations c
        JOIN users u ON (u.id = c.participant1 OR u.id = c.participant2)
        WHERE (c.participant1 = ${userId} OR c.participant2 = ${userId})
          AND u.id != ${userId} 
          AND u.is_admin = true
        ORDER BY c.id, c.last_message_at DESC
        LIMIT 1
      `);
      return result.rows;
    } catch (error) {
      console.error('Error in getUserConversations:', error);
      return [];
    }
  }

  async updateUserStatus(userId: string, isOnline: boolean) {
    try {
      await this.drizzle.db
        .update(users)
        .set({
          isOnline,
          lastSeen: isOnline ? null : new Date(),
        })
        .where(eq(users.id, userId));
    } catch (error) {
      console.warn('Could not update user status:', error.message);
    }
  }
}
