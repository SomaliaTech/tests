// lib/features/chat/domain/entities/chat_user.dart
import 'package:equatable/equatable.dart';

class ChatUser extends Equatable {
  final String id;
  final String? name;
  final String phoneNumber;
  final String? profileImage;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isAdmin;
  final bool? isSuperAdmin;

  const ChatUser({
    required this.id,
    this.name,
    required this.phoneNumber,
    this.profileImage,
    required this.isOnline,
    this.lastSeen,
    required this.isAdmin,
    this.isSuperAdmin,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String?,
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      profileImage: json['profileImage'] as String?,
      isOnline: json['isOnline'] == true || json['is_online'] == true,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
      isAdmin: json['isAdmin'] == true || json['is_admin'] == true,
      isSuperAdmin:
          json['isSuperAdmin'] == true || json['is_super_admin'] == true,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phoneNumber,
    isOnline,
    isAdmin,
    isSuperAdmin,
  ];
}
