import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/admin/presentation/screens/admin_main_navigation_screen.dart';
import 'package:toastification/toastification.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../order/presentation/screens/order_history_screen.dart';
import '../../../profile/presentation/widgets/profile_section.dart';
import '../../../profile/presentation/widgets/logout_button.dart';
import '../../../profile/presentation/widgets/menu_item.dart';
import '../../../support/presentation/screens/support_screen.dart';
import '../../../../core/services/injection_container.dart';
import '../../../../core/services/storage/storage_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final StorageService _storageService = sl<StorageService>();
  String? _userName;
  String? _userPhone;
  String? _userProfileImage;
  bool _isAdmin = false;
  bool _isSuperAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// ✅ Returns Future<void> so it can be used with RefreshIndicator
  Future<void> _loadUserData() async {
    try {
      final name = await _storageService.getUserName();
      final phone = await _storageService.getUserPhone();
      final profileImage = await _storageService.getUserProfileImage();
      final isAdmin = await _storageService.getIsAdmin();
      final isSuperAdmin = await _storageService.getIsSuperAdmin();

      debugPrint(
        '👤 SettingsView - isAdmin: $isAdmin, isSuperAdmin: $isSuperAdmin',
      );

      if (mounted) {
        setState(() {
          _userName = name;
          _userPhone = phone;
          _userProfileImage = profileImage;
          _isAdmin = isAdmin;
          _isSuperAdmin = isSuperAdmin;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to load user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleLogout(BuildContext context) {
    final authBloc = context.read<AuthBloc>();

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                  authBloc.add(LogoutEvent());
                  toastification.show(
                    title: const Text('Logged Out'),
                    description: const Text(
                      'You have been logged out successfully',
                    ),
                    type: ToastificationType.success,
                    style: ToastificationStyle.fillColored,
                    autoCloseDuration: const Duration(seconds: 2),
                  );
                },
                isDestructiveAction: true,
                child: const Text('Logout'),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  authBloc.add(LogoutEvent());
                  toastification.show(
                    title: const Text('Logged Out'),
                    description: const Text(
                      'You have been logged out successfully',
                    ),
                    type: ToastificationType.success,
                    style: ToastificationStyle.fillColored,
                    autoCloseDuration: const Duration(seconds: 2),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF4757),
                ),
                child: const Text('Logout'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            Navigator.pushReplacementNamed(context, '/');
          }
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // ✅ Scrollable content area
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadUserData,
                      color: const Color(0xFF2ED573),
                      backgroundColor: Colors.white,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          children: [
                            ProfileSection(
                              userName: _userName,
                              userPhone: _userPhone,
                              profileImage: _userProfileImage,
                            ),
                            const SizedBox(height: 10),
                            Container(
                              color: Colors.white,
                              child: Column(
                                children: [
                                  MenuItem(
                                    onTap: () => Navigator.push(
                                      context,
                                      OrderHistoryScreen.route(),
                                    ),
                                    id: 'order-history',
                                    title: 'Order history',
                                    icon: Iconsax.receipt,
                                  ),
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFE0E0E0),
                                  ),
                                  MenuItem(
                                    onTap: () => Navigator.push(
                                      context,
                                      SupportScreen.route(),
                                    ),
                                    id: 'help-center',
                                    title: 'Help center',
                                    icon: Iconsax.info_circle,
                                  ),
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFE0E0E0),
                                  ),

                                  // ✅ Show Admin Dashboard for both Admin and Super Admin
                                  if (_isAdmin || _isSuperAdmin) ...[
                                    MenuItem(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AdminMainNavigationScreen(),
                                          ),
                                        );
                                      },
                                      id: 'admin-dashboard',
                                      title: _isSuperAdmin
                                          ? 'Super Admin Dashboard'
                                          : 'Admin Dashboard',
                                      icon: Iconsax.chart_square,
                                    ),
                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // ✅ Add some padding at the bottom of scrollable content
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ✅ Logout button fixed at the bottom
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: LogoutButton(onTap: () => _handleLogout(context)),
                  ),
                  // ✅ Safe area for devices with bottom navigation bar
                  const SizedBox(height: 120),
                ],
              ),
      ),
    );
  }
}
