import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/error/error_handler.dart';
import 'package:mobile/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:mobile/features/notifications/domain/entities/notification.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:mobile/features/notifications/presentation/widgets/empty_state.dart';
import 'package:mobile/features/notifications/presentation/widgets/filter_tab.dart';
import 'package:mobile/features/notifications/presentation/widgets/notification_card.dart';
import 'package:mobile/features/order/presentation/screens/order_details_screen.dart';

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
        centerTitle: false,
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoaded) {
                return TextButton(
                  onPressed: () {
                    if (state.unreadCount > 0) {
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
                content: Row(
                  children: [
                    const Icon(
                      Iconsax.tick_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: const Color(0xFF2ED573),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is NotificationsError) {
            ErrorHandler.showError(context, state.message);
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
                    child: state.isEmpty
                        ? EmptyState(filter: state.currentFilter)
                        : RefreshIndicator(
                            onRefresh: () async {
                              context.read<NotificationsBloc>().add(
                                RefreshNotifications(),
                              );
                            },
                            color: const Color(0xFF2ED573),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(15),
                              itemCount: state.filteredNotifications.length,
                              itemBuilder: (context, index) {
                                final notification =
                                    state.filteredNotifications[index];
                                return NotificationCard(
                                  notification: notification,
                                  onMarkRead: () {
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
                ],
              );
            }

            if (state is NotificationsError) {
              return _buildErrorState(context, state.message);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  // ==========================================
  // NOTIFICATION PRESS HANDLER
  // ==========================================

  void _handleNotificationPress(
    BuildContext context,
    NotificationEntity notification,
  ) {
    if (!notification.read) {
      context.read<NotificationsBloc>().add(
        MarkNotificationAsRead(notification.id),
      );
    }

    debugPrint(
      '🔔 Notification pressed: type=${notification.type}, actionLink=${notification.actionLink}',
    );

    // Handle navigation based on notification type
    if (notification.type != null) {
      switch (notification.type) {
        case 'order':
          _navigateToOrder(context, notification);
          break;
        case 'message':
        case 'new_message':
          _navigateToChat(context, notification);
          break;
        case 'payment':
          _navigateToPayment(context, notification);
          break;
        case 'product':
          _navigateToProduct(context, notification);
          break;
        case 'system':
          _navigateFromActionLink(
            context,
            notification.actionLink,
            notification,
          );
          break;
        default:
          _navigateFromActionLink(
            context,
            notification.actionLink,
            notification,
          );
          break;
      }
    } else {
      _navigateFromActionLink(context, notification.actionLink, notification);
    }
  }

  // ==========================================
  // NAVIGATION HELPERS
  // ==========================================

  void _navigateFromActionLink(
    BuildContext context,
    String? actionLink,
    NotificationEntity notification,
  ) {
    if (actionLink == null || actionLink.isEmpty) return;

    debugPrint('🔗 Navigating to: $actionLink');

    final uri = Uri.tryParse(actionLink);
    if (uri == null) return;

    final segments = uri.path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return;

    switch (segments[0]) {
      case 'orders':
        if (segments.length >= 2) {
          _navigateToOrderById(context, segments[1]);
        }
        break;
      case 'products':
        if (segments.length >= 2) {
          _navigateToProductById(context, segments[1]);
        }
        break;
      case 'chat':
        if (segments.length >= 2) {
          // ✅ Extract name from notification title
          final partnerName = _extractNameFromTitle(notification.title);
          _navigateToChatById(context, segments[1], partnerName);
        }
        break;
      case 'home':
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 'admin':
        if (segments.length >= 2) {
          if (segments[1] == 'orders' && segments.length >= 3) {
            _navigateToOrderById(context, segments[2]);
          } else if (segments[1] == 'products' && segments.length >= 3) {
            _navigateToProductById(context, segments[2]);
          } else {
            Navigator.pushNamed(context, '/admin');
          }
        } else {
          Navigator.pushNamed(context, '/admin');
        }
        break;
      case 'settings':
      case 'profile':
        Navigator.pushNamed(context, '/settings');
        break;
      default:
        debugPrint('⚠️ Unknown action link pattern: $actionLink');
        break;
    }
  }

  void _navigateToOrder(BuildContext context, NotificationEntity notification) {
    final orderId = _extractIdFromLink(notification.actionLink, 'orders');
    if (orderId != null) {
      _navigateToOrderById(context, orderId);
    } else {
      _navigateFromActionLink(context, notification.actionLink, notification);
    }
  }

  void _navigateToChat(BuildContext context, NotificationEntity notification) {
    final partnerId = _extractIdFromLink(notification.actionLink, 'chat');
    if (partnerId != null) {
      // ✅ Extract name from notification title (e.g., "New message from Hussein mahamed")
      final partnerName = _extractNameFromTitle(notification.title);
      _navigateToChatById(context, partnerId, partnerName);
    } else {
      _navigateFromActionLink(context, notification.actionLink, notification);
    }
  }

  void _navigateToPayment(
    BuildContext context,
    NotificationEntity notification,
  ) {
    _navigateToOrder(context, notification);
  }

  void _navigateToProduct(
    BuildContext context,
    NotificationEntity notification,
  ) {
    final productId = _extractIdFromLink(notification.actionLink, 'products');
    if (productId != null) {
      _navigateToProductById(context, productId);
    } else {
      _navigateFromActionLink(context, notification.actionLink, notification);
    }
  }

  void _navigateToOrderById(BuildContext context, String orderId) {
    debugPrint('📦 Navigating to order: $orderId');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(orderId: orderId),
      ),
    );
  }

  void _navigateToChatById(
    BuildContext context,
    String partnerId, [
    String partnerName = 'User',
  ]) {
    debugPrint('💬 Navigating to chat with: $partnerId ($partnerName)');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          partnerId: partnerId,
          partnerName: partnerName,
          isOnline: false,
        ),
      ),
    );
  }

  void _navigateToProductById(BuildContext context, String productId) {
    debugPrint('🛍️ Navigating to product: $productId');
    Navigator.pushNamed(
      context,
      '/product-details',
      arguments: {'productId': productId},
    );
  }

  // ==========================================
  // LINK PARSING HELPERS
  // ==========================================

  /// ✅ Extract partner name from notification title
  /// Examples:
  /// - "New message from Hussein mahamed" -> "Hussein mahamed"
  /// - "New message from +252615328654" -> "+252615328654"
  /// - "Payment Successful" -> "User" (fallback)
  String _extractNameFromTitle(String? title) {
    if (title == null || title.isEmpty) return 'User';

    // Try to extract name after "from "
    if (title.contains('from ')) {
      return title.split('from ').last.trim();
    }

    // Try common patterns
    final patterns = ['from ', 'with ', 'by '];
    for (final pattern in patterns) {
      if (title.contains(pattern)) {
        return title.split(pattern).last.trim();
      }
    }

    return 'User';
  }

  String? _extractIdFromLink(String? actionLink, String resource) {
    if (actionLink == null || actionLink.isEmpty) return null;
    try {
      final uri = Uri.parse(actionLink);
      final segments = uri.path.split('/').where((s) => s.isNotEmpty).toList();
      final resourceIndex = segments.indexOf(resource);
      if (resourceIndex != -1 && resourceIndex + 1 < segments.length) {
        return segments[resourceIndex + 1];
      }
    } catch (e) {
      debugPrint('❌ Failed to extract ID from link: $e');
    }
    return null;
  }

  String? _extractOrderIdFromActionLink(String? actionLink) {
    return _extractIdFromLink(actionLink, 'orders');
  }

  // ==========================================
  // DIALOGS
  // ==========================================

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

  // ==========================================
  // ERROR STATE
  // ==========================================

  Widget _buildErrorState(BuildContext context, String message) {
    final friendlyMessage = ErrorHandler.parseError(message);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.warning_2, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to load notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              friendlyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<NotificationsBloc>().add(LoadNotifications());
              },
              icon: const Icon(Iconsax.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ED573),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
