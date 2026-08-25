import 'package:equatable/equatable.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';

// ✅ ADD 'message' to the enum
enum NotificationType { order, promotion, system, payment, message }

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.order:
        return 'order';
      case NotificationType.promotion:
        return 'promotion';
      case NotificationType.system:
        return 'system';
      case NotificationType.payment:
        return 'payment';
      case NotificationType.message:
        return 'message';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.order:
        return Iconsax.tick_circle;
      case NotificationType.promotion:
        return Iconsax.tag;
      case NotificationType.system:
        return Iconsax.user;
      case NotificationType.payment:
        return Iconsax.card;
      case NotificationType.message:
        return Iconsax.message;
    }
  }

  Color get iconColor {
    switch (this) {
      case NotificationType.order:
        return const Color(0xFF3742FA);
      case NotificationType.promotion:
        return const Color(0xFFFFA502);
      case NotificationType.system:
        return const Color(0xFF666666);
      case NotificationType.payment:
        return const Color(0xFF2ED573);
      case NotificationType.message:
        return const Color(0xFF1877F2); // Message blue
    }
  }

  Color get iconBackground {
    switch (this) {
      case NotificationType.order:
        return const Color(0xFFE3F2FD);
      case NotificationType.promotion:
        return const Color(0xFFFFF3E0);
      case NotificationType.system:
        return const Color(0xFFF5F5F5);
      case NotificationType.payment:
        return const Color(0xFFE8F5E9);
      case NotificationType.message:
        return const Color(0xFFE3F2FD); // Light blue background
    }
  }
}

// ✅ Added 'messages' to filter enum
enum NotificationFilter { all, unread, orders, promotions, messages }

extension NotificationFilterExtension on NotificationFilter {
  String get displayName {
    switch (this) {
      case NotificationFilter.all:
        return 'All';
      case NotificationFilter.unread:
        return 'Unread';
      case NotificationFilter.orders:
        return 'Orders';
      case NotificationFilter.promotions:
        return 'Promotions';
      case NotificationFilter.messages:
        return 'Messages';
    }
  }
}

class NotificationEntity extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime date;
  final bool read;
  final String? actionText;
  final String? actionLink;
  final String? imageUrl;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.date,
    required this.read,
    this.actionText,
    this.actionLink,
    this.imageUrl,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    final weeks = (difference.inDays / 7).floor();
    return '${weeks}w ago';
  }

  NotificationEntity copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? date,
    bool? read,
    String? actionText,
    String? actionLink,
    String? imageUrl,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      read: read ?? this.read,
      actionText: actionText ?? this.actionText,
      actionLink: actionLink ?? this.actionLink,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    final typeValue = json['type']?.toString().toLowerCase() ?? 'system';

    NotificationType type;
    switch (typeValue) {
      case 'order':
        type = NotificationType.order;
        break;
      case 'promotion':
      case 'promo':
        type = NotificationType.promotion;
        break;
      case 'payment':
        type = NotificationType.payment;
        break;
      case 'message': // ✅ ADDED MESSAGE TYPE
        type = NotificationType.message;
        break;
      case 'system':
      case 'admin':
        type = NotificationType.system;
        break;
      default:
        print('⚠️ Unknown type: $typeValue');
        type = NotificationType.system;
    }

    return NotificationEntity(
      id: json['id']?.toString() ?? '',
      type: type,
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      date: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      read: json['isRead'] == true || json['is_read'] == true,
      actionText:
          json['actionText']?.toString() ?? json['action_text']?.toString(),
      actionLink:
          json['actionLink']?.toString() ?? json['action_link']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    message,
    date,
    read,
    actionText,
    actionLink,
    imageUrl,
  ];
}
