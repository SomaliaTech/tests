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
    return ConversationModel(
      partnerId: json['id'] as String,
      partnerName: (json['name'] ?? 'User') as String,
      partnerImage: (json['profileImage'] ?? json['profile_image']) as String?,
      isOnline: (json['isOnline'] ?? json['is_online'] ?? false) as bool,
      lastMessage: (json['lastMessage'] ?? json['last_message']) as String?,
      lastMessageType:
          (json['lastMessageType'] ?? json['last_message_type'] ?? 'text')
              as String,
      lastMessageTime: DateTime.parse(
        (json['lastMessageTime'] ?? json['last_message_time']) as String,
      ),
      unreadCount:
          int.tryParse(
            (json['unreadCount'] ?? json['unread_count']).toString(),
          ) ??
          0,
    );
  }
}
