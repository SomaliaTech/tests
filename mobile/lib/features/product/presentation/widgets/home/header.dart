import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_event.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_state.dart';
import 'package:mobile/features/cart/presentation/screens/cart_screen.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:mobile/features/notifications/presentation/screens/notifications_screen.dart';

class Header extends StatefulWidget {
  final Function(String)? onSearch;

  const Header({super.key, this.onSearch});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  StreamSubscription? _notificationSub;

  // ✅ Cache the last known unread count to prevent flickering
  int _cachedUnreadCount = 0;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _setupRealtimeNotifications();
    });
  }

  void _loadData() {
    if (mounted) {
      context.read<CartBloc>().add(LoadCartEvent());
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated ||
        authState is OtpVerified ||
        authState is ProfileCompleted) {
      if (mounted) {
        context.read<NotificationsBloc>().add(LoadNotifications());
      }
    }
  }

  void _setupRealtimeNotifications() {
    try {
      final socketService = GetIt.instance<ChatSocketService>();
      _notificationSub = socketService.onNewNotification.listen((data) {
        if (mounted) {
          // ✅ Increment cached count immediately for instant feedback
          setState(() {
            _cachedUnreadCount++;
          });
          // Then refresh from API in background
          context.read<NotificationsBloc>().add(LoadNotifications());
        }
      });
    } catch (e) {
      // Socket service not available
    }
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2ED573),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 15),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "HALDOOR",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  Row(
                    children: [
                      _NotificationIcon(
                        cachedCount: _cachedUnreadCount,
                        hasLoadedOnce: _hasLoadedOnce,
                      ),
                      const SizedBox(width: 5),
                      const _CartIcon(),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _SearchBar(onSearch: widget.onSearch),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ Notification Icon - No flickering
class _NotificationIcon extends StatelessWidget {
  final int cachedCount;
  final bool hasLoadedOnce;

  const _NotificationIcon({
    required this.cachedCount,
    required this.hasLoadedOnce,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isAuthenticated =
            authState is Authenticated ||
            authState is OtpVerified ||
            authState is ProfileCompleted;

        if (!isAuthenticated) {
          return IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please login to view notifications'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Iconsax.notification, color: Colors.white),
          );
        }

        return BlocBuilder<NotificationsBloc, NotificationsState>(
          // ✅ Only rebuild when count actually changes
          buildWhen: (previous, current) {
            if (previous is NotificationsLoaded &&
                current is NotificationsLoaded) {
              return previous.unreadCount != current.unreadCount;
            }
            if (previous is NotificationsLoading &&
                current is NotificationsLoaded) {
              return true;
            }
            return false;
          },
          builder: (context, state) {
            int unreadCount = cachedCount;

            if (state is NotificationsLoaded) {
              unreadCount = state.unreadCount;
            }

            return Stack(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    ).then((_) {
                      if (context.mounted) {
                        context.read<NotificationsBloc>().add(
                          LoadNotifications(),
                        );
                      }
                    });
                  },
                  icon: const Icon(Iconsax.notification, color: Colors.white),
                ),
                // ✅ Show badge if count > 0, regardless of loading state
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF4757),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

// ✅ Cart Icon - No flickering
class _CartIcon extends StatelessWidget {
  const _CartIcon();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      // ✅ Only rebuild when count changes
      buildWhen: (previous, current) {
        if (previous is CartLoaded && current is CartLoaded) {
          return previous.itemCount != current.itemCount;
        }
        if (current is CartLoaded) {
          return true;
        }
        return false;
      },
      builder: (context, state) {
        int itemCount = 0;

        if (state is CartLoaded) {
          itemCount = state.itemCount;
        }

        return Stack(
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
              icon: const Icon(Iconsax.shopping_cart, color: Colors.white),
            ),
            if (itemCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4757),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    itemCount > 99 ? '99+' : itemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ✅ Search Bar - Now with search button and clear functionality
class _SearchBar extends StatefulWidget {
  final Function(String)? onSearch;

  const _SearchBar({this.onSearch});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _controller.text.trim();
    if (query.isNotEmpty && widget.onSearch != null) {
      widget.onSearch!(query);
    }
  }

  void _clearSearch() {
    _controller.clear();
    // Trigger empty search to reset results
    if (widget.onSearch != null) {
      widget.onSearch!('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Iconsax.search_normal, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _performSearch(),
              decoration: InputDecoration(
                hintText: "Search product here",
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(
                Iconsax.close_circle,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: _clearSearch,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          IconButton(
            icon: const Icon(
              Iconsax.search_normal_1,
              color: Color(0xFF2ED573),
              size: 20,
            ),
            onPressed: _performSearch,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
