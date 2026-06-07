import 'package:fpdart/fpdart.dart';

import '../entities/notification.dart';

class Failure {
  final String message;
  const Failure(this.message);
}

abstract class NotificationsRepository {
  Future<Either<Failure, List<NotificationEntity>>> getNotifications();
  Future<Either<Failure, void>> markAsRead(String id);
  Future<Either<Failure, void>> markAllAsRead();
  Future<Either<Failure, void>> deleteNotification(String id);
  Future<Either<Failure, void>> clearAllNotifications();
}
