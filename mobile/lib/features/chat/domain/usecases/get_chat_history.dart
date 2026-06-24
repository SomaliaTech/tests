import '../../../../core/utils/typedefs.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class GetChatHistory {
  final ChatRepository repository;
  const GetChatHistory(this.repository);

  ResultFuture<List<ChatMessage>> call(String partnerId) async =>
      repository.getChatHistory(partnerId);
}
