import { Injectable, NotFoundException } from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { notifications } from '../drizzle/schema';
import { eq, and, desc, sql } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';
import {
  CreateNotificationDto,
  UpdateNotificationDto,
} from './dto/notification.dto';
import { NotificationType } from './notification.entity';

@Injectable()
export class NotificationsService {
  constructor(private drizzle: DrizzleService) {}

  async create(createNotificationDto: CreateNotificationDto) {
    const [notification] = await this.drizzle.db
      .insert(notifications)
      .values({
        id: uuidv4(),
        userId: createNotificationDto.userId,
        type: createNotificationDto.type,
        title: createNotificationDto.title,
        message: createNotificationDto.message,
        isRead: false,
        actionText: createNotificationDto.actionText,
        actionLink: createNotificationDto.actionLink,
        createdAt: new Date(),
      })
      .returning();

    return notification;
  }

  async getUserNotifications(userId: string) {
    console.log('🔍 Fetching notifications for userId:', userId);

    const result = await this.drizzle.db
      .select()
      .from(notifications)
      .where(eq(notifications.userId, userId))
      .orderBy(desc(notifications.createdAt));

    console.log(`📊 Found ${result.length} notifications for user ${userId}`);
    return result;
  }

  async getUnreadCount(userId: string) {
    const result = await this.drizzle.db
      .select({ count: sql<number>`count(*)` })
      .from(notifications)
      .where(
        and(eq(notifications.userId, userId), eq(notifications.isRead, false)),
      );

    return { unreadCount: Number(result[0]?.count) || 0 };
  }

  async markAsRead(notificationId: string, userId: string) {
    const [notification] = await this.drizzle.db
      .update(notifications)
      .set({ isRead: true })
      .where(
        and(
          eq(notifications.id, notificationId),
          eq(notifications.userId, userId),
        ),
      )
      .returning();

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    return notification;
  }

  async markAllAsRead(userId: string) {
    await this.drizzle.db
      .update(notifications)
      .set({ isRead: true })
      .where(eq(notifications.userId, userId));

    return { message: 'All notifications marked as read' };
  }

  async deleteNotification(notificationId: string, userId: string) {
    const [deleted] = await this.drizzle.db
      .delete(notifications)
      .where(
        and(
          eq(notifications.id, notificationId),
          eq(notifications.userId, userId),
        ),
      )
      .returning();

    if (!deleted) {
      throw new NotFoundException('Notification not found');
    }

    return { message: 'Notification deleted successfully' };
  }

  async clearAllNotifications(userId: string) {
    await this.drizzle.db
      .delete(notifications)
      .where(eq(notifications.userId, userId));

    return { message: 'All notifications cleared' };
  }

  // ==========================================
  // HELPER METHODS FOR DIFFERENT NOTIFICATION TYPES
  // ==========================================

  async createOrderNotification(
    userId: string,
    orderNumber: string,
    orderId: string,
    status: string,
  ) {
    return this.create({
      userId,
      type: NotificationType.ORDER,
      title: `Order ${status}`,
      message: `Your order #${orderNumber} has been ${status.toLowerCase()}`,
      actionText: 'View Order',
      actionLink: `/orders/${orderId}`,
    });
  }

  async createPaymentNotification(
    userId: string,
    orderNumber: string,
    orderId: string,
    amount: number,
  ) {
    return this.create({
      userId,
      type: NotificationType.PAYMENT,
      title: 'Payment Received',
      message: `Payment of $${amount.toFixed(2)} for order #${orderNumber} was received successfully`,
      actionText: 'View Order',
      actionLink: `/orders/${orderId}`,
    });
  }

  async createPromotionNotification(
    userId: string,
    title: string,
    message: string,
    actionText?: string,
    actionLink?: string,
  ) {
    return this.create({
      userId,
      type: NotificationType.PROMOTION,
      title,
      message,
      actionText,
      actionLink,
    });
  }

  async createSystemNotification(
    userId: string,
    title: string,
    message: string,
  ) {
    return this.create({
      userId,
      type: NotificationType.SYSTEM,
      title,
      message,
    });
  }

  // ==========================================
  // UPDATE METHODS
  // ==========================================

  async updateNotification(
    notificationId: string,
    updateNotificationDto: UpdateNotificationDto,
  ) {
    const updateData: any = {};
    if (updateNotificationDto.isRead !== undefined) {
      updateData.isRead = updateNotificationDto.isRead;
    }

    const [notification] = await this.drizzle.db
      .update(notifications)
      .set(updateData)
      .where(eq(notifications.id, notificationId))
      .returning();

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    return notification;
  }
}
