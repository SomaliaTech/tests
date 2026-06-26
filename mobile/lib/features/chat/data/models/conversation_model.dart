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
      // ✅ FIX: Use 'userId' from backend, not 'id'
      final partnerId =
          (json['userId'] ?? json['id'] ?? json['partnerId'] ?? '').toString();

      print(
        '🔍 Parsing conversation - partnerId: $partnerId, name: ${json['name']}',
      );

      // Parse isOnline safely
      final rawIsOnline = json['isOnline'] ?? json['is_online'];
      bool parsedIsOnline = false;
      if (rawIsOnline is bool) {
        parsedIsOnline = rawIsOnline;
      } else if (rawIsOnline is num) {
        parsedIsOnline = rawIsOnline == 1;
      } else if (rawIsOnline is String) {
        parsedIsOnline =
            rawIsOnline.toLowerCase() == 'true' || rawIsOnline == '1';
      }

      return ConversationModel(
        partnerId: partnerId,
        partnerName: (json['name'] ?? json['partnerName'] ?? 'User').toString(),
        partnerImage:
            json['profileImage'] ??
            json['profile_image'] ??
            json['partnerImage'] as String?,
        isOnline: parsedIsOnline,
        lastMessage: json['lastMessage'] ?? json['last_message'] as String?,
        lastMessageType:
            (json['lastMessageType'] ?? json['last_message_type'] ?? 'text')
                .toString(),
        lastMessageTime:
            json['lastMessageTime'] != null || json['last_message_time'] != null
            ? DateTime.parse(
                (json['lastMessageTime'] ?? json['last_message_time'])
                    .toString(),
              )
            : DateTime.now(),
        unreadCount:
            int.tryParse(
              (json['unreadCount'] ?? json['unread_count'] ?? 0).toString(),
            ) ??
            0,
      );
    } catch (e, stackTrace) {
      print('❌ [ConversationModel] PARSING ERROR: $e');
      print('📦 [ConversationModel] CORRUPTED JSON PAYLOAD: $json');
      print('🦺 [ConversationModel] STACKTRACE: $stackTrace');
      rethrow;
    }
  }
}
