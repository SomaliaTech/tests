// lib/features/main/presentation/screens/main_navigation_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/core/common/widgets/network_aware_wrapper.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/chat/presentation/screens/conversations_screen.dart';
import 'package:mobile/features/product/presentation/screens/home_screen.dart';
import 'package:mobile/features/profile/presentation/screens/settings_screen.dart';
import 'package:mobile/features/wishlist/presentation/screens/wishlist_screen.dart';
import 'package:iconsax/iconsax.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  int _unreadCount = 0;
  StreamSubscription? _messageSub;
  StreamSubscription? _statusSub;

  late final ChatSocketService _socketService;

  final List<Widget> _screens = [
    const HomeScreen(),
    const WishlistScreen(),
    const ConversationsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    try {
      _socketService = GetIt.instance<ChatSocketService>();
      _setupUnreadListener();
    } catch (e) {
      debugPrint('⚠️ ChatSocketService not available: $e');
    }
  }

  void _setupUnreadListener() {
    // Listen for new messages to increment unread count
    _messageSub = _socketService.onNewMessage.listen((message) {
      if (!mounted) return;

      // Only increment if not on chat screen
      if (_selectedIndex != 2) {
        setState(() {
          _unreadCount++;
        });
      }
    });

    // Reset unread count when entering chat screen
    // or when messages are marked as read
    _statusSub = _socketService.onMessageRead.listen((data) {
      if (!mounted) return;
      // Update unread count from server periodically
      _fetchUnreadCount();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Reset unread count when entering chat
      if (index == 2) {
        _unreadCount = 0;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Refresh unread count when app resumes
      _fetchUnreadCount();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    // Optional: Fetch from API if needed
    // This would require injecting the chat remote data source
  }

  @override
  Widget build(BuildContext context) {
    return NetworkAwareWrapper(
      showBanner: true, // Show connecting banner for unstable connections
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.unselectedColor,
          showUnselectedLabels: true,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Favorite',
            ),
            BottomNavigationBarItem(
              icon: _buildChatIcon(),
              activeIcon: const Icon(Iconsax.message),
              label: 'Chat',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the chat icon with unread badge
  Widget _buildChatIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Iconsax.message_search4),
        if (_unreadCount > 0)
          Positioned(
            top: -4,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
