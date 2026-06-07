import 'package:fpdart/fpdart.dart';

import '../repositories/notifications_repository.dart';

class DeleteNotification {
  final NotificationsRepository repository;

  DeleteNotification(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteNotification(id);
  }
}
