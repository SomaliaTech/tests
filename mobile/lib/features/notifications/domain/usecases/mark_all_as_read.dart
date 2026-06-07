import 'package:fpdart/fpdart.dart';

import '../repositories/notifications_repository.dart';

class MarkAllAsRead {
  final NotificationsRepository repository;

  MarkAllAsRead(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.markAllAsRead();
  }
}
