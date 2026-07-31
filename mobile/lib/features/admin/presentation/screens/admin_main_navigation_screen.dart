import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get_it/get_it.dart';

import 'package:mobile/core/constants/admin_permissions.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/core/services/permission_service.dart';
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
  int _selectedIndex = 0;
  bool _isLoadingTabs = true;
  bool _isRedirecting = false;
  bool _isBuildingTabs = false;

  List<_AdminTab> _tabs = [];

  StreamSubscription? _roleChangeSub;

  @override
  void initState() {
    super.initState();

    // ✅ Always load fresh permissions when entering admin area
    _buildTabs(forceRefresh: true);

    // ✅ Listen for realtime role changes
    _setupRoleChangeListener();
  }

  @override
  void dispose() {
    _roleChangeSub?.cancel();
    super.dispose();
  }

  /// ✅ Build tabs based on admin permissions
  Future<void> _buildTabs({bool forceRefresh = false}) async {
    if (_isBuildingTabs) return;

    _isBuildingTabs = true;

    try {
      final permissionService = GetIt.instance<PermissionService>();

      final permissions = await permissionService
          .loadPermissions(forceRefresh: forceRefresh)
          .timeout(const Duration(seconds: 10), onTimeout: () => <String>[]);

      debugPrint('🧭 [AdminNav] Loaded permissions: $permissions');

      bool allowed(String? permission) {
        // No permission required
        if (permission == null) return true;

        // Super admin wildcard
        if (permissions.contains('*')) return true;

        // Normal permission check
        return AdminPermissions.has(permissions, permission);
      }

      final allTabs = [
        _AdminTab(
          icon: Iconsax.chart,
          activeIcon: Iconsax.chart_2,
          label: 'Dashboard',
          screen: const AdminDashboardScreen(),
          permission: null,
        ),
        _AdminTab(
          icon: Iconsax.box_1,
          activeIcon: Iconsax.box,
          label: 'Products',
          screen: const AdminProductsScreen(),
          permission: AdminPermissions.productView,
        ),
        _AdminTab(
          icon: Iconsax.shopping_cart,
          activeIcon: Iconsax.shopping_bag,
          label: 'Orders',
          screen: const AdminOrdersScreen(),
          permission: AdminPermissions.orderView,
        ),
        _AdminTab(
          icon: Iconsax.setting_2,
          activeIcon: Iconsax.setting,
          label: 'Settings',
          screen: const AdminSettingsScreen(),
          permission: null,
        ),
      ];

      final visibleTabs = allTabs
          .where((tab) => allowed(tab.permission))
          .toList();

      // ✅ Should not happen because Dashboard and Settings have null permission,
      // but keep safe fallback.
      if (visibleTabs.isEmpty) {
        visibleTabs.add(
          _AdminTab(
            icon: Iconsax.setting_2,
            activeIcon: Iconsax.setting,
            label: 'Settings',
            screen: const AdminSettingsScreen(),
            permission: null,
          ),
        );
      }

      // ✅ Try to keep requested initial tab if it is visible
      int targetIndex = 0;

      if (widget.initialIndex >= 0 && widget.initialIndex < allTabs.length) {
        final requestedLabel = allTabs[widget.initialIndex].label;

        final foundIndex = visibleTabs.indexWhere(
          (tab) => tab.label == requestedLabel,
        );

        if (foundIndex != -1) {
          targetIndex = foundIndex;
        }
      }

      if (!mounted) return;

      setState(() {
        _tabs = visibleTabs;
        _selectedIndex = targetIndex;
        _isLoadingTabs = false;
      });
    } catch (e) {
      debugPrint('❌ [AdminNav] Failed to build tabs: $e');

      if (!mounted) return;

      // ✅ Safe fallback: do NOT show Products/Orders if permissions fail
      setState(() {
        _tabs = [
          _AdminTab(
            icon: Iconsax.chart,
            activeIcon: Iconsax.chart_2,
            label: 'Dashboard',
            screen: const AdminDashboardScreen(),
            permission: null,
          ),
          _AdminTab(
            icon: Iconsax.setting_2,
            activeIcon: Iconsax.setting,
            label: 'Settings',
            screen: const AdminSettingsScreen(),
            permission: null,
          ),
        ];

        _selectedIndex = 0;
        _isLoadingTabs = false;
      });
    } finally {
      _isBuildingTabs = false;
    }
  }

  /// ✅ Listen for backend role_changed event
  void _setupRoleChangeListener() {
    try {
      final socketService = GetIt.instance<ChatSocketService>();

      _roleChangeSub = socketService.onRoleChange.listen((data) {
        final isAdmin = data['isAdmin'] as bool? ?? false;
        final isSuperAdmin = data['isSuperAdmin'] as bool? ?? false;

        debugPrint(
          '🔔 [AdminNav] role_changed -> isAdmin: $isAdmin, isSuperAdmin: $isSuperAdmin',
        );

        if (!isAdmin && !isSuperAdmin) {
          _redirectToMainNavigation();
        } else {
          // ✅ Still admin, but permissions may have changed
          GetIt.instance<PermissionService>().invalidate();
          _buildTabs(forceRefresh: true);
        }
      });
    } catch (e) {
      debugPrint('❌ [AdminNav] Role listener failed: $e');
    }
  }

  /// ✅ Redirect when admin access is revoked
  void _redirectToMainNavigation() {
    if (_isRedirecting) return;

    _isRedirecting = true;

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

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTabs || _tabs.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs.map((tab) => tab.screen).toList(),
      ),
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
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.4), width: 1),
            ),
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
                  for (int i = 0; i < _tabs.length; i++)
                    _buildNavItem(tab: _tabs[i], index: i),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required _AdminTab tab, required int index}) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isSelected ? tab.activeIcon : tab.icon,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                ),
                child: Text(tab.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;
  final String? permission;

  const _AdminTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
    this.permission,
  });
}
