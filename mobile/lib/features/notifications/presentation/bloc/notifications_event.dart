import 'package:equatable/equatable.dart';
import 'package:mobile/features/notifications/domain/entities/notification.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationsEvent {}

// Renamed from MarkAsRead to MarkNotificationAsRead
class MarkNotificationAsRead extends NotificationsEvent {
  final String id;
  const MarkNotificationAsRead(this.id);

  @override
  List<Object?> get props => [id];
}

// Renamed from MarkAllAsRead to MarkAllNotificationsAsRead
class MarkAllNotificationsAsRead extends NotificationsEvent {}

// Renamed from DeleteNotification to DeleteNotificationEvent
class DeleteNotificationEvent extends NotificationsEvent {
  final String id;
  const DeleteNotificationEvent(this.id);

  @override
  List<Object?> get props => [id];
}

// Renamed from ClearAllNotifications to ClearAllNotificationsEvent
class ClearAllNotificationsEvent extends NotificationsEvent {}

class SetNotificationFilter extends NotificationsEvent {
  final NotificationFilter filter;
  const SetNotificationFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}

class RefreshNotifications extends NotificationsEvent {}
