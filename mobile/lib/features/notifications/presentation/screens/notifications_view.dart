import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/notifications/domain/entities/notification.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:mobile/features/notifications/presentation/widgets/empty_state.dart';
import 'package:mobile/features/notifications/presentation/widgets/filter_tab.dart';
import 'package:mobile/features/notifications/presentation/widgets/notification_card.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoaded) {
                return TextButton(
                  onPressed: () {
                    if (state.unreadCount > 0) {
                      // Fixed: Use MarkAllNotificationsAsRead
                      context.read<NotificationsBloc>().add(
                        MarkAllNotificationsAsRead(),
                      );
                    } else {
                      _showClearAllDialog(context);
                    }
                  },
                  child: Text(
                    state.unreadCount > 0 ? 'Mark all read' : 'Clear all',
                    style: const TextStyle(
                      color: Color(0xFF2ED573),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocListener<NotificationsBloc, NotificationsState>(
        listener: (context, state) {
          if (state is NotificationsSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFF2ED573),
              ),
            );
          } else if (state is NotificationsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2ED573)),
              );
            }

            if (state is NotificationsLoaded) {
              return Column(
                children: [
                  // Filter Tabs
                  Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          FilterTab(
                            isActive:
                                state.currentFilter == NotificationFilter.all,
                            label: 'All',
                            onTap: () => context.read<NotificationsBloc>().add(
                              const SetNotificationFilter(
                                NotificationFilter.all,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilterTab(
                            isActive:
                                state.currentFilter ==
                                NotificationFilter.unread,
                            label: 'Unread (${state.unreadCount})',
                            onTap: () => context.read<NotificationsBloc>().add(
                              const SetNotificationFilter(
                                NotificationFilter.unread,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilterTab(
                            isActive:
                                state.currentFilter ==
                                NotificationFilter.orders,
                            label: 'Orders',
                            onTap: () => context.read<NotificationsBloc>().add(
                              const SetNotificationFilter(
                                NotificationFilter.orders,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilterTab(
                            isActive:
                                state.currentFilter ==
                                NotificationFilter.promotions,
                            label: 'Promotions',
                            onTap: () => context.read<NotificationsBloc>().add(
                              const SetNotificationFilter(
                                NotificationFilter.promotions,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Notifications List
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context.read<NotificationsBloc>().add(
                          RefreshNotifications(),
                        );
                      },
                      color: const Color(0xFF2ED573),
                      child: state.isEmpty
                          ? EmptyState(filter: state.currentFilter)
                          : ListView.builder(
                              padding: const EdgeInsets.all(15),
                              itemCount: state.filteredNotifications.length,
                              itemBuilder: (context, index) {
                                final notification =
                                    state.filteredNotifications[index];
                                return NotificationCard(
                                  notification: notification,
                                  onMarkRead: () {
                                    // Fixed: Use MarkNotificationAsRead
                                    context.read<NotificationsBloc>().add(
                                      MarkNotificationAsRead(notification.id),
                                    );
                                  },
                                  onDelete: () {
                                    _showDeleteDialog(context, notification.id);
                                  },
                                  onPress: () {
                                    _handleNotificationPress(
                                      context,
                                      notification,
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ),

                  // Footer Action
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Notification'),
          content: const Text(
            'Are you sure you want to delete this notification?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Fixed: Use DeleteNotificationEvent
                context.read<NotificationsBloc>().add(
                  DeleteNotificationEvent(id),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF4757),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear All Notifications'),
          content: const Text(
            'Are you sure you want to delete all notifications?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Fixed: Use ClearAllNotificationsEvent
                context.read<NotificationsBloc>().add(
                  ClearAllNotificationsEvent(),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF4757),
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  void _handleNotificationPress(
    BuildContext context,
    NotificationEntity notification,
  ) {
    if (!notification.read) {
      // Fixed: Use MarkNotificationAsRead
      context.read<NotificationsBloc>().add(
        MarkNotificationAsRead(notification.id),
      );
    }

    if (notification.actionLink != null) {
      // Navigate based on action link
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigate to: ${notification.actionLink}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}
