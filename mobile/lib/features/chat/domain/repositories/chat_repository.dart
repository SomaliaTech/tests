import '../../../../core/utils/typedefs.dart';
import '../entities/chat_message.dart';
import '../entities/conversation.dart';

abstract class ChatRepository {
  ResultFuture<List<Conversation>> getConversations();
  ResultFuture<List<ChatMessage>> getChatHistory(String partnerId);
  ResultFuture<void> markAsRead(String partnerId);
}
