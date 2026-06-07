import 'package:fpdart/fpdart.dart';

import '../repositories/notifications_repository.dart';

class ClearAllNotifications {
  final NotificationsRepository repository;

  ClearAllNotifications(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.clearAllNotifications();
  }
}
