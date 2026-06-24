import '../../../../core/utils/typedefs.dart';
import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class GetConversations {
  final ChatRepository repository;
  const GetConversations(this.repository);

  ResultFuture<List<Conversation>> call() async =>
      repository.getConversations();
}
