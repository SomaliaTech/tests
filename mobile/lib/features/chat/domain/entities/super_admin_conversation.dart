// lib/features/chat/domain/entities/super_admin_conversation.dart
class SuperAdminConversation {
  final String conversationId;
  final SuperAdminUser admin;
  final SuperAdminUser user;
  final String? lastMessage;
  final String? lastMessageType;
  final DateTime? lastMessageTime;
  final DateTime? createdAt;

  SuperAdminConversation({
    required this.conversationId,
    required this.admin,
    required this.user,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageTime,
    this.createdAt,
  });

  factory SuperAdminConversation.fromJson(Map<String, dynamic> json) {
    return SuperAdminConversation(
      conversationId: json['conversationId']?.toString() ?? '',
      admin: SuperAdminUser.fromJson(json['admin'] ?? {}),
      user: SuperAdminUser.fromJson(json['user'] ?? {}),
      lastMessage: json['lastMessage']?.toString(),
      lastMessageType: json['lastMessageType']?.toString(),
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.tryParse(json['lastMessageTime'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class SuperAdminUser {
  final String id;
  final String name;
  final String? phone;
  final String? image;
  final bool isOnline;

  SuperAdminUser({
    required this.id,
    required this.name,
    this.phone,
    this.image,
    this.isOnline = false,
  });

  factory SuperAdminUser.fromJson(Map<String, dynamic> json) {
    return SuperAdminUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      phone: json['phone']?.toString(),
      image: json['image']?.toString(),
      isOnline: json['isOnline'] == true,
    );
  }
}
