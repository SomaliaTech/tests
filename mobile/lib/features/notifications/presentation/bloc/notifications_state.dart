import 'package:equatable/equatable.dart';
import 'package:mobile/features/notifications/domain/entities/notification.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationEntity> notifications;
  final NotificationFilter currentFilter;

  const NotificationsLoaded({
    required this.notifications,
    required this.currentFilter,
  });

  int get unreadCount => notifications.where((n) => !n.read).length;

  List<NotificationEntity> get filteredNotifications {
    switch (currentFilter) {
      case NotificationFilter.all:
        return notifications;
      case NotificationFilter.unread:
        return notifications.where((n) => !n.read).toList();
      case NotificationFilter.orders:
        return notifications
            .where((n) => n.type == NotificationType.order)
            .toList();
      case NotificationFilter.promotions:
        return notifications
            .where((n) => n.type == NotificationType.promotion)
            .toList();
      // ✅ ADDED: Handle the new messages filter
      case NotificationFilter.messages:
        return notifications
            .where((n) => n.type == NotificationType.message)
            .toList();
    }
  }

  bool get isEmpty => filteredNotifications.isEmpty;

  @override
  List<Object?> get props => [notifications, currentFilter];
}

class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}

class NotificationsSuccess extends NotificationsState {
  final String message;
  const NotificationsSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
