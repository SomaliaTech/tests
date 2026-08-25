import 'package:fpdart/fpdart.dart';

import '../entities/notification.dart';
import '../repositories/notifications_repository.dart';

// In get_notifications.dart
class GetNotifications {
  final NotificationsRepository repository;
  GetNotifications(this.repository);

  Future<Either<Failure, List<NotificationEntity>>> call({
    bool forceRefresh = false,
  }) {
    return repository.getNotifications(forceRefresh: forceRefresh);
  }
}
