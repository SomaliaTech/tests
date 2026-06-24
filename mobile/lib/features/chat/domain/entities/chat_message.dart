import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String? content;
  final String type;
  final String? mediaUrl;
  final bool isRead;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.content,
    required this.type,
    this.mediaUrl,
    required this.isRead,
    required this.createdAt,
  });

  // ✅ ADD THIS METHOD
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id:
          json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      senderId:
          json['sender_id']?.toString() ?? json['senderId']?.toString() ?? '',
      receiverId:
          json['receiver_id']?.toString() ??
          json['receiverId']?.toString() ??
          '',
      content: json['content'] as String?,
      type: json['type'] as String? ?? 'text',
      mediaUrl: json['media_url'] as String? ?? json['mediaUrl'] as String?,
      isRead: json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  // ✅ ADD THIS METHOD for optimistic updates
  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    String? type,
    String? mediaUrl,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'type': type,
      'media_url': mediaUrl,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    senderId,
    receiverId,
    content,
    type,
    mediaUrl,
    isRead,
    createdAt,
  ];
}
