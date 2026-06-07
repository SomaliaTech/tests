import 'package:fpdart/fpdart.dart';

import '../repositories/notifications_repository.dart';

class MarkAsRead {
  final NotificationsRepository repository;

  MarkAsRead(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.markAsRead(id);
  }
}
