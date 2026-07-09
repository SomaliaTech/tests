// lib/features/chat/data/models/conversation_model.dart
import '../../domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.partnerId,
    required super.partnerName,
    super.partnerImage,
    required super.isOnline,
    super.lastMessage,
    required super.lastMessageType,
    required super.lastMessageTime,
    required super.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    try {
      final partnerId = (json['userId'] ?? json['user_id'] ?? '').toString();

      final rawIsOnline = json['isOnline'] ?? json['is_online'];
      final bool parsedIsOnline = _parseBool(rawIsOnline);

      // ✅ Parse UTC timestamp and convert to local
      DateTime lastMessageTime = DateTime.now();
      final rawTime =
          json['lastMessageTime'] ??
          json['last_message_time'] ??
          json['lastMessageAt'] ??
          json['last_message_at'];

      if (rawTime != null) {
        try {
          if (rawTime is String) {
            // Parse ISO string and convert to local
            lastMessageTime = DateTime.parse(rawTime).toLocal();
          } else if (rawTime is DateTime) {
            lastMessageTime = rawTime.toLocal();
          }
        } catch (e) {
          print('❌ [ConversationModel] Error parsing time: $e');
          lastMessageTime = DateTime.now();
        }
      }

      return ConversationModel(
        partnerId: partnerId,
        partnerName: (json['name'] ?? json['partnerName'] ?? 'User').toString(),
        partnerImage:
            json['profileImage'] ??
            json['profile_image'] ??
            json['partnerImage'],
        isOnline: parsedIsOnline,
        lastMessage: json['lastMessage'] ?? json['last_message'],
        lastMessageType:
            (json['lastMessageType'] ?? json['last_message_type'] ?? 'text')
                .toString(),
        lastMessageTime: lastMessageTime,
        unreadCount:
            int.tryParse(
              (json['unreadCount'] ?? json['unread_count'] ?? 0).toString(),
            ) ??
            0,
      );
    } catch (e, stackTrace) {
      print('❌ [ConversationModel] PARSING ERROR: $e');
      print('📦 [ConversationModel] PAYLOAD: $json');
      print('🦺 [ConversationModel] STACKTRACE: $stackTrace');
      rethrow;
    }
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }
}
