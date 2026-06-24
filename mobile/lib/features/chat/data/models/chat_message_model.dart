import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    super.content,
    required super.type,
    super.mediaUrl,
    required super.isRead,
    required super.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      // 🚨 FIX: Handle both camelCase and snake_case
      senderId: (json['senderId'] ?? json['sender_id']) as String,
      receiverId: (json['receiverId'] ?? json['receiver_id']) as String,
      content: json['content'] as String?,
      type: (json['type'] ?? 'text') as String,
      mediaUrl: (json['mediaUrl'] ?? json['media_url']) as String?,
      isRead: (json['isRead'] ?? json['is_read'] ?? false) as bool,
      createdAt: DateTime.parse(
        (json['createdAt'] ?? json['created_at']) as String,
      ),
    );
  }
}
