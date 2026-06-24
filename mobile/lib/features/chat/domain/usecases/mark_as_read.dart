import '../../../../core/utils/typedefs.dart';
import '../repositories/chat_repository.dart';

class MarkAsRead {
  final ChatRepository repository;
  const MarkAsRead(this.repository);

  ResultFuture<void> call(String partnerId) async =>
      repository.markAsRead(partnerId);
}
