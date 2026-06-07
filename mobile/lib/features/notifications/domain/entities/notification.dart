import 'package:equatable/equatable.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';

enum NotificationType { order, promotion, system, payment }

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
    }
  }
}

enum NotificationFilter { all, unread, orders, promotions }

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

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.date,
    required this.read,
    this.actionText,
    this.actionLink,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    }
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
  ];
}
