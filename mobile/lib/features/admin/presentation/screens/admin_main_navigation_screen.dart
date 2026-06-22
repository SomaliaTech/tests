import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_products_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_settings_screen.dart';

class AdminMainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const AdminMainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminMainNavigationScreen> createState() =>
      _AdminMainNavigationScreenState();
}

class _AdminMainNavigationScreenState extends State<AdminMainNavigationScreen> {
  late int _selectedIndex;

  // The 4 tabs for the Admin area
  final List<Widget> _screens = [
    AdminDashboardScreen(),
    const AdminProductsScreen(),
    const AdminOrdersScreen(),
    const AdminSettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.unselectedColor,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Iconsax.chart),
            activeIcon: Icon(Iconsax.chart_2),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.box_1),
            activeIcon: Icon(Iconsax.box),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.shopping_cart),
            activeIcon: Icon(Iconsax.shopping_bag),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.setting_2),
            activeIcon: Icon(Iconsax.setting),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
