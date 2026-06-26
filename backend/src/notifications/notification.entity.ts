export enum NotificationType {
  ORDER = 'order',
  PROMOTION = 'promotion',
  SYSTEM = 'system',
  PAYMENT = 'payment',
  MESSAGE = 'message', // ✅ Add this
}
export class Notification {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  message: string;
  isRead: boolean;
  actionText?: string;
  actionLink?: string;
  createdAt: Date;
  updatedAt: Date;
}
