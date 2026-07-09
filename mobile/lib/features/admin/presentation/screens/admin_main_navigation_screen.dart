import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
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
  StreamSubscription? _roleChangeSub;
  bool _isRedirecting = false;

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
    _setupRoleChangeListener();
  }

  // ✅ Listen for role changes from server
  void _setupRoleChangeListener() {
    try {
      final socketService = GetIt.instance<ChatSocketService>();

      _roleChangeSub = socketService.onRoleChange.listen((data) {
        final isAdmin = data['isAdmin'] as bool? ?? false;
        final isSuperAdmin = data['isSuperAdmin'] as bool? ?? false;

        debugPrint(
          '🔔 [AdminNav] Role change detected: isAdmin=$isAdmin, isSuperAdmin=$isSuperAdmin',
        );

        // ✅ If user lost admin access, redirect to main navigation
        if (!isAdmin && !isSuperAdmin && !_isRedirecting) {
          _redirectToMainNavigation();
        }
      });
    } catch (e) {
      debugPrint('❌ [AdminNav] Failed to setup role change listener: $e');
    }
  }

  // ✅ Redirect to main navigation with notification
  void _redirectToMainNavigation() {
    if (_isRedirecting) return;
    _isRedirecting = true;

    debugPrint('🔄 [AdminNav] Redirecting to main navigation...');

    // Show notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Iconsax.warning_2, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Your admin access has been revoked')),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    // ✅ Pop back to main navigation after showing notification
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _roleChangeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // ✅ Content scrolls behind the glass
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _buildLiquidGlassNavBar(),
    );
  }

  Widget _buildLiquidGlassNavBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            // ✅ Apple-style liquid glass gradient
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.85),
                Colors.white.withOpacity(0.75),
                Colors.white.withOpacity(0.80),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            // ✅ Subtle border for glass edge
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.4), width: 1),
            ),
            // ✅ Soft shadow for depth
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Iconsax.chart,
                    activeIcon: Iconsax.chart_2,
                    label: 'Dashboard',
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Iconsax.box_1,
                    activeIcon: Iconsax.box,
                    label: 'Products',
                    index: 1,
                  ),
                  _buildNavItem(
                    icon: Iconsax.shopping_cart,
                    activeIcon: Iconsax.shopping_bag,
                    label: 'Orders',
                    index: 2,
                  ),
                  _buildNavItem(
                    icon: Iconsax.setting_2,
                    activeIcon: Iconsax.setting,
                    label: 'Settings',
                    index: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Icon with liquid glass effect when selected
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  // ✅ Subtle glow when selected
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              // ✅ Label with smooth color transition
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
