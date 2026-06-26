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
    try {
      print('📦 Parsing message: $json'); // Add this debug line

      return ChatMessageModel(
        id: (json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
            .toString(),
        senderId: (json['senderId'] ?? json['sender_id'] ?? '').toString(),
        receiverId: (json['receiverId'] ?? json['receiver_id'] ?? '')
            .toString(),
        content: json['content'] as String?,
        type: (json['type'] ?? 'text').toString(),
        mediaUrl: json['mediaUrl'] ?? json['media_url'] as String?,
        isRead: _parseBool(json['isRead'] ?? json['is_read']),
        createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      );
    } catch (e, stackTrace) {
      print('❌ [ChatMessageModel] PARSING ERROR: $e');
      print('📦 Payload: $json');
      rethrow;
    }
  }
  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
