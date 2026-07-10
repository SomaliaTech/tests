// lib/features/chat/domain/entities/chat_message.dart
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
  final String? senderName;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.content,
    required this.type,
    this.mediaUrl,
    this.senderName,
    required this.isRead,
    required this.createdAt,
  });

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
      // ✅ FIX: Parse UTC string and convert to local time
      createdAt: _parseUtcToLocal(json['created_at'] ?? json['createdAt']),
    );
  }

  /// Parses UTC ISO string or DateTime and converts to local time
  static DateTime _parseUtcToLocal(dynamic value) {
    if (value == null) return DateTime.now();

    try {
      DateTime utcTime;

      if (value is String) {
        utcTime = DateTime.parse(value);
      } else if (value is DateTime) {
        utcTime = value;
      } else {
        return DateTime.now();
      }

      // ✅ Convert UTC to local time
      // If the time is already in UTC, toLocal() will convert it
      // If it's already local, toLocal() returns the same time
      return utcTime.toLocal();
    } catch (e) {
      print('❌ [ChatMessage] Error parsing datetime: $e');
      return DateTime.now();
    }
  }

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
      'created_at': createdAt.toUtc().toIso8601String(), // ✅ Send as UTC
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
