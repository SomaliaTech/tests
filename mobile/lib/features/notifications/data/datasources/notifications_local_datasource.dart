import '../../domain/entities/notification.dart';

class NotificationsLocalDataSource {
  List<NotificationEntity> _notifications = [];

  NotificationsLocalDataSource() {
    _notifications = _getMockData();
  }

  Future<List<NotificationEntity>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _notifications;
  }

  Future<void> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(read: true);
    }
  }

  Future<void> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
  }

  Future<void> deleteNotification(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _notifications.removeWhere((n) => n.id == id);
  }

  Future<void> clearAllNotifications() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _notifications.clear();
  }

  List<NotificationEntity> _getMockData() {
    final now = DateTime.now();

    return [
      NotificationEntity(
        id: '1',
        type: NotificationType.order,
        title: 'Order Delivered',
        message:
            'Your order ORD-2024-001 has been delivered successfully. Thank you for shopping with SOOMAR!',
        date: now.subtract(const Duration(hours: 2)),
        read: false,
        actionText: 'View Order',
        actionLink: '/order-details/ORD-2024-001',
      ),
      NotificationEntity(
        id: '2',
        type: NotificationType.order,
        title: 'Order Shipped',
        message:
            'Your order ORD-2024-002 is out for delivery. Expected delivery: Today by 6 PM',
        date: now.subtract(const Duration(hours: 5)),
        read: false,
        actionText: 'Track Order',
        actionLink: '/tracking/ORD-2024-002',
      ),
      NotificationEntity(
        id: '3',
        type: NotificationType.promotion,
        title: 'Special Offer! 🎉',
        message:
            'Get 20% off on all electronics. Use code: SAVE20. Valid until June 15, 2026',
        date: now.subtract(const Duration(days: 1)),
        read: true,
        actionText: 'Shop Now',
        actionLink: '/category/electronics',
      ),
      NotificationEntity(
        id: '4',
        type: NotificationType.payment,
        title: 'Payment Received',
        message:
            'We have received your payment of \$36.00 for order ORD-2024-001',
        date: now.subtract(const Duration(days: 2)),
        read: true,
      ),
      NotificationEntity(
        id: '5',
        type: NotificationType.system,
        title: 'Profile Updated',
        message: 'Your profile information has been successfully updated',
        date: now.subtract(const Duration(days: 3)),
        read: true,
      ),
      NotificationEntity(
        id: '6',
        type: NotificationType.promotion,
        title: 'New Arrivals',
        message: 'Check out our latest products in Home & Kitchen category',
        date: now.subtract(const Duration(days: 5)),
        read: true,
        actionText: 'Browse',
        actionLink: '/category/home-kitchen',
      ),
      NotificationEntity(
        id: '7',
        type: NotificationType.order,
        title: 'Order Confirmed',
        message:
            'Your order ORD-2024-003 has been confirmed and is being processed',
        date: now.subtract(const Duration(days: 7)),
        read: true,
      ),
    ];
  }
}
