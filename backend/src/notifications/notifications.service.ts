import {
  Injectable,
  NotFoundException,
  Inject,
  forwardRef,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { DrizzleService } from '../drizzle/drizzle.service';
import { notifications, deviceTokens, users } from '../drizzle/schema';
import { eq, and, desc, sql, inArray, like, or, SQL } from 'drizzle-orm';
import { v4 as uuidv4 } from 'uuid';
import {
  CreateNotificationDto,
  UpdateNotificationDto,
} from './dto/notification.dto';
import { NotificationType } from './notification.entity';
import { ChatGateway } from '../chat/chat.gateway';
import { FirebaseService } from '../firebase/firebase.service';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private drizzle: DrizzleService,
    @Inject(forwardRef(() => ChatGateway))
    private chatGateway: ChatGateway,
    private firebaseService: FirebaseService,
  ) {}

  // ==========================================
  // CREATE NOTIFICATION
  // ==========================================

  /**
   * ✅ Create notification - sends to DB, WebSocket, AND Firebase push
   */
  async create(createNotificationDto: CreateNotificationDto) {
    this.logger.log(
      `Creating notification for user: ${createNotificationDto.userId}`,
    );

    // Validate user exists
    const [user] = await this.drizzle.db
      .select({ id: users.id })
      .from(users)
      .where(eq(users.id, createNotificationDto.userId))
      .limit(1);

    if (!user) {
      throw new BadRequestException('User not found');
    }

    // 1. Save to database
    const [notification] = await this.drizzle.db
      .insert(notifications)
      .values({
        id: uuidv4(),
        userId: createNotificationDto.userId,
        type: createNotificationDto.type,
        title: createNotificationDto.title.trim(),
        message: createNotificationDto.message.trim(),
        isRead: false,
        actionText: createNotificationDto.actionText?.trim(),
        actionLink: createNotificationDto.actionLink?.trim(),
        createdAt: new Date(),
      })
      .returning();

    this.logger.log(`Notification saved to DB: ${notification.id}`);

    // 2. Emit WebSocket event
    await this._emitWebSocket(notification);

    // 3. Send Firebase push notification
    await this._sendPushNotification(notification);

    return notification;
  }

  /**
   * ✅ Bulk create notifications
   */
  async bulkCreateNotifications(body: {
    userIds: string[];
    type: NotificationType;
    title: string;
    message: string;
    actionText?: string;
    actionLink?: string;
  }) {
    if (body.userIds.length > 50) {
      throw new BadRequestException(
        'Cannot create notifications for more than 50 users at once',
      );
    }

    const results: any[] = []; // ✅ Add explicit type
    for (const userId of body.userIds) {
      try {
        const result = await this.create({
          userId,
          type: body.type,
          title: body.title,
          message: body.message,
          actionText: body.actionText,
          actionLink: body.actionLink,
        });
        results.push(result);
      } catch (error) {
        this.logger.warn(
          `Failed to create notification for user ${userId}: ${error}`,
        );
      }
    }

    this.logger.log(`Bulk created ${results.length} notifications`);
    return {
      message: `${results.length} notifications created successfully`,
      notifications: results,
    };
  }

  // ==========================================
  // PRIVATE HELPERS
  // ==========================================

  private async _emitWebSocket(notification: any): Promise<void> {
    return new Promise((resolve) => {
      try {
        this.chatGateway.server
          .to(`user:${notification.userId}`)
          .emit('new_notification', {
            id: notification.id,
            userId: notification.userId,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            actionText: notification.actionText,
            actionLink: notification.actionLink,
            createdAt: notification.createdAt.toISOString(),
            isRead: false,
          });
        this.logger.debug(`WebSocket emitted for user ${notification.userId}`);
        resolve();
      } catch (error) {
        this.logger.warn(`WebSocket emit failed: ${error}`);
        resolve(); // Still resolve so it doesn't block
      }
    });
  }

  private async _sendPushNotification(notification: any): Promise<void> {
    try {
      // Get user's device tokens
      const tokens = await this.drizzle.db
        .select({ token: deviceTokens.token })
        .from(deviceTokens)
        .where(
          and(
            eq(deviceTokens.userId, notification.userId),
            eq(deviceTokens.isActive, true),
          ),
        );

      const deviceTokensList = tokens.map((t) => t.token);

      if (deviceTokensList.length === 0) {
        this.logger.debug(`No device tokens for user ${notification.userId}`);
        return;
      }

      // Prepare data payload
      const data: Record<string, string> = {
        type: notification.type,
        notificationId: notification.id,
      };

      if (notification.actionLink) {
        if (notification.actionLink.includes('/orders/')) {
          data.orderId = notification.actionLink.split('/orders/')[1];
        } else if (notification.actionLink.includes('/chat/')) {
          data.senderId = notification.actionLink.split('/chat/')[1];
        }
      }

      // Send push notification
      const result = await this.firebaseService.sendMulticastNotification(
        deviceTokensList,
        notification.title,
        notification.message,
        data,
      );

      this.logger.log(
        `Push sent: ${result.successCount} devices, ${result.failureCount} failed`,
      );
    } catch (error) {
      this.logger.warn(`Push notification failed: ${error}`);
    }
  }

  // ==========================================
  // USER ENDPOINTS
  // ==========================================

  async getUserNotifications(
    userId: string,
    page: number = 1,
    limit: number = 20,
    type?: NotificationType,
    isRead?: boolean,
  ) {
    const offset = (page - 1) * limit;
    const conditions: SQL[] = [eq(notifications.userId, userId)];

    if (type) {
      conditions.push(eq(notifications.type, type));
    }

    if (isRead !== undefined) {
      conditions.push(eq(notifications.isRead, isRead));
    }

    const whereClause = and(...conditions);

    const [items, total] = await Promise.all([
      this.drizzle.db
        .select()
        .from(notifications)
        .where(whereClause)
        .orderBy(desc(notifications.createdAt))
        .limit(Math.min(limit, 50))
        .offset(offset),
      this.drizzle.db
        .select({ count: sql<number>`COUNT(*)::int` })
        .from(notifications)
        .where(whereClause),
    ]);

    return {
      items,
      pagination: {
        page,
        limit,
        total: total[0]?.count || 0,
        totalPages: Math.ceil((total[0]?.count || 0) / limit),
      },
    };
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
  // ADMIN ENDPOINTS
  // ==========================================

  async getAllNotificationsAdmin(
    page: number = 1,
    limit: number = 20,
    userId?: string,
    type?: NotificationType,
  ) {
    const offset = (page - 1) * limit;
    const conditions: SQL[] = [];

    if (userId) {
      conditions.push(eq(notifications.userId, userId));
    }

    if (type) {
      conditions.push(eq(notifications.type, type));
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    const [items, total] = await Promise.all([
      this.drizzle.db
        .select()
        .from(notifications)
        .where(whereClause)
        .orderBy(desc(notifications.createdAt))
        .limit(Math.min(limit, 50))
        .offset(offset),
      this.drizzle.db
        .select({ count: sql<number>`COUNT(*)::int` })
        .from(notifications)
        .where(whereClause),
    ]);

    // Get user names for each notification
    const userIds = [...new Set(items.map((n) => n.userId))];
    const userMap = new Map();

    if (userIds.length > 0) {
      const usersList = await this.drizzle.db
        .select({
          id: users.id,
          name: users.name,
          phoneNumber: users.phoneNumber,
        })
        .from(users)
        .where(inArray(users.id, userIds));

      usersList.forEach((u) => userMap.set(u.id, u));
    }

    const formattedItems = items.map((notification) => ({
      ...notification,
      user: userMap.get(notification.userId) || null,
    }));

    return {
      items: formattedItems,
      pagination: {
        page,
        limit,
        total: total[0]?.count || 0,
        totalPages: Math.ceil((total[0]?.count || 0) / limit),
      },
    };
  }

  async updateNotification(
    notificationId: string,
    updateNotificationDto: UpdateNotificationDto,
  ) {
    const updateData: any = {};

    if (updateNotificationDto.isRead !== undefined) {
      updateData.isRead = updateNotificationDto.isRead;
    }

    if (updateNotificationDto.title !== undefined) {
      updateData.title = updateNotificationDto.title.trim();
    }

    if (updateNotificationDto.message !== undefined) {
      updateData.message = updateNotificationDto.message.trim();
    }

    if (updateNotificationDto.actionText !== undefined) {
      updateData.actionText = updateNotificationDto.actionText?.trim();
    }

    if (updateNotificationDto.actionLink !== undefined) {
      updateData.actionLink = updateNotificationDto.actionLink?.trim();
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

  async deleteNotificationAdmin(notificationId: string) {
    const [deleted] = await this.drizzle.db
      .delete(notifications)
      .where(eq(notifications.id, notificationId))
      .returning();

    if (!deleted) {
      throw new NotFoundException('Notification not found');
    }

    return { message: 'Notification deleted successfully' };
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

  async createAdminNotification(
    userId: string,
    title: string,
    message: string,
    actionText?: string,
    actionLink?: string,
  ) {
    return this.create({
      userId,
      type: NotificationType.ADMIN,
      title,
      message,
      actionText,
      actionLink,
    });
  }
}
