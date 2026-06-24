import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartBloc>().add(LoadCartEvent());

      // ✅ Only load notifications if user is authenticated
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated ||
          authState is OtpVerified ||
          authState is ProfileCompleted) {
        context.read<NotificationsBloc>().add(LoadNotifications());
      }
    });
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
                      // Notification Icon with Badge
                      _NotificationIcon(),
                      const SizedBox(width: 5),
                      // Cart Icon with Badge
                      _CartIcon(),
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

// ✅ Separate widget for notification icon
class _NotificationIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isAuthenticated =
            authState is Authenticated ||
            authState is OtpVerified ||
            authState is ProfileCompleted;

        // Only show notifications if authenticated
        if (!isAuthenticated) {
          return IconButton(
            onPressed: () {
              // Show login required message
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
          builder: (context, state) {
            int unreadCount = 0;

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
                    );
                  },
                  icon: const Icon(Iconsax.notification, color: Colors.white),
                ),
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

// ✅ Separate widget for cart icon
class _CartIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
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

// ✅ Separate widget for search bar
class _SearchBar extends StatelessWidget {
  final Function(String)? onSearch;

  const _SearchBar({this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        onSubmitted: onSearch,
        decoration: InputDecoration(
          hintText: "Search product here",
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(
            Iconsax.search_normal,
            color: Colors.grey,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
