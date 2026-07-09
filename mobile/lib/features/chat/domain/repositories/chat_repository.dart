import 'package:mobile/features/chat/domain/entities/chat_user.dart';

import '../../../../core/utils/typedefs.dart';
import '../entities/chat_message.dart';
import '../entities/conversation.dart';

abstract class ChatRepository {
  ResultFuture<List<Conversation>> getConversations();
  ResultFuture<List<ChatMessage>> getChatHistory(String partnerId);
  ResultFuture<void> markAsRead(String partnerId);
  ResultFuture<List<Map<String, dynamic>>> getAvailableAdmins();
  ResultFuture<Map<String, dynamic>> createConversation(String participantId);
  ResultFuture<ChatMessage> sendMessage({
    required String receiverId,
    String? content,
    String type = 'text',
    String? mediaUrl,
  });
  ResultFuture<Map<String, dynamic>> getUnreadCount();

  ResultFuture<List<Conversation>> searchConversations(String query);
  ResultFuture<List<ChatUser>> getAdminUsersForChat();
}
