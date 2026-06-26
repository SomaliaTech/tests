import '../../../../core/utils/typedefs.dart';
import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class SearchConversations {
  final ChatRepository repository;
  const SearchConversations(this.repository);

  ResultFuture<List<Conversation>> call(String query) async =>
      repository.searchConversations(query);
}
