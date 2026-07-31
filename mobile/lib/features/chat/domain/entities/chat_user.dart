// lib/features/chat/domain/entities/chat_user.dart
class ChatUser {
  final String id;
  final String? name;
  final String phoneNumber;
  final String? profileImage;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isAdmin;
  final bool? isSuperAdmin; // ✅ Add this field

  ChatUser({
    required this.id,
    this.name,
    required this.phoneNumber,
    this.profileImage,
    this.isOnline = false,
    this.lastSeen,
    this.isAdmin = false,
    this.isSuperAdmin, // ✅ Add this field
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? '',
      name: json['name'],
      phoneNumber: json['phoneNumber'] ?? json['phone_number'] ?? '',
      profileImage: json['profileImage'] ?? json['profile_image'],
      isOnline: json['isOnline'] ?? json['is_online'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString()) ??
                (json['last_seen'] != null
                    ? DateTime.tryParse(json['last_seen'].toString())
                    : null)
          : null,
      isAdmin: json['isAdmin'] ?? json['is_admin'] ?? false,
      isSuperAdmin:
          json['isSuperAdmin'] ?? json['is_super_admin'], // ✅ Add this
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'isAdmin': isAdmin,
      'isSuperAdmin': isSuperAdmin, // ✅ Add this
    };
  }
}
