import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:mobile/features/order/presentation/screens/order_history_screen.dart';

// Import your other screens here
// import 'package:mobile/features/home/presentation/screens/home_screen.dart';
// import 'package:mobile/features/order/presentation/screens/order_history_screen.dart';
// import 'package:mobile/features/profile/presentation/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Define the screens for each tab
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      // const HomeScreen(), // Replace with your actual HomeScreen
      const AdminDashboardScreen(), // YOUR NEW DASHBOARD TAB
      const OrderHistoryScreen(), // Replace with your actual Orders Screen
      // const ProfileScree(), // Replace with your actual Profile Screen
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps the state of each tab alive (e.g., scroll position, loaded data)
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.backgroundColor,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.unselectedColor,
        showUnselectedLabels: true,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Iconsax.home),
            activeIcon: Icon(Iconsax.home_1),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.chart),
            activeIcon: Icon(Iconsax.chart_2),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.shopping_cart),
            activeIcon: Icon(Iconsax.shopping_bag),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.user),
            activeIcon: Icon(Iconsax.user_octagon),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
