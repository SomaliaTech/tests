import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/notifications/domain/entities/notification.dart';

class NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;
  final VoidCallback onPress;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onMarkRead,
    required this.onDelete,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.read;
    final hasImage =
        notification.imageUrl != null && notification.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (isUnread) onMarkRead();
        onPress();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isUnread
              ? Border.all(
                  color: const Color(0xFF2ED573).withValues(alpha: 0.3),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLeading(hasImage),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2ED573),
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111111),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          notification.timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    if (notification.actionText != null &&
                        notification.actionText!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ED573).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              notification.actionText!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2ED573),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Iconsax.arrow_right_3,
                              size: 14,
                              color: Color(0xFF2ED573),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(bool hasImage) {
    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: notification.imageUrl!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 64,
            height: 64,
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallbackIcon(),
        ),
      );
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    IconData icon;
    Color color;
    Color bgColor;

    switch (notification.type) {
      case NotificationType.order:
        icon = Iconsax.tick_circle;
        color = const Color(0xFF3742FA);
        bgColor = const Color(0xFFE3F2FD);
        break;
      case NotificationType.promotion:
        icon = Iconsax.tag;
        color = const Color(0xFFFFA502);
        bgColor = const Color(0xFFFFF3E0);
        break;
      case NotificationType.system:
        icon = Iconsax.user;
        color = const Color(0xFF666666);
        bgColor = const Color(0xFFF5F5F5);
        break;
      case NotificationType.payment:
        icon = Iconsax.card;
        color = const Color(0xFF2ED573);
        bgColor = const Color(0xFFE8F5E9);
        break;
      // ✅ ADDED: Handle the new message type
      case NotificationType.message:
        icon = Iconsax.message;
        color = const Color(0xFF1877F2);
        bgColor = const Color(0xFFE3F2FD);
        break;
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 28, color: color),
    );
  }
}
