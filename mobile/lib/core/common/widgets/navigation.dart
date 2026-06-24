import 'package:flutter/material.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/chat/presentation/screens/chat_view.dart';
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

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const WishlistScreen(),

    ConversationsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.unselectedColor,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorite',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.message_search4),
            activeIcon: Icon(Iconsax.message),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
