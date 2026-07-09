// lib/features/chat/data/models/chat_message_model.dart
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
      return ChatMessageModel(
        id: (json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString())
            .toString(),
        senderId: (json['senderId'] ?? json['sender_id'] ?? '').toString(),
        receiverId: (json['receiverId'] ?? json['receiver_id'] ?? '')
            .toString(),
        content: json['content'],
        type: (json['type'] ?? 'text').toString(),
        mediaUrl: json['mediaUrl'] ?? json['media_url'],
        isRead: _parseBool(json['isRead'] ?? json['is_read']),
        // ✅ FIX: Parse UTC and convert to local
        createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      );
    } catch (e, stackTrace) {
      print('❌ [ChatMessageModel] PARSING ERROR: $e');
      print('📦 [ChatMessageModel] PAYLOAD: $json');
      rethrow;
    }
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  /// Parses datetime and converts UTC to local timezone
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    try {
      DateTime parsedTime;

      if (value is String) {
        // Parse the ISO 8601 string (assumed to be UTC from backend)
        parsedTime = DateTime.parse(value);
      } else if (value is DateTime) {
        parsedTime = value;
      } else {
        return DateTime.now();
      }

      // ✅ Convert UTC to local timezone
      return parsedTime.toLocal();
    } catch (e) {
      print('❌ [ChatMessageModel] Error parsing datetime: $value, error: $e');
      return DateTime.now();
    }
  }
}
