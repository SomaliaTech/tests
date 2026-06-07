import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/notifications/domain/entities/notification.dart';

class EmptyState extends StatelessWidget {
  final NotificationFilter filter;

  const EmptyState({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    final isUnreadFilter = filter == NotificationFilter.unread;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnreadFilter ? Iconsax.notification : Iconsax.notification,
                size: 50,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isUnreadFilter ? 'No Unread Notifications' : 'No Notifications',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUnreadFilter
                  ? "You're all caught up!"
                  : "Notifications about your orders and promotions will appear here",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
