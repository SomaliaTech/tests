import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/error/failures.dart';
import '../repositories/chat_repository.dart';

class MarkAsRead {
  final ChatRepository repository;

  MarkAsRead(this.repository);

  Future<Either<Failure, void>> call(String partnerId) async {
    return await repository.markAsRead(partnerId);
  }
}
