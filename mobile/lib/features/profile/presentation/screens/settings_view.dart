import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/admin/presentation/screens/admin_dashboard_screen.dart';
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
  bool _isAdmin = false; // 👈 1. Added to track admin status

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await _storageService.getUserName();
    final phone = await _storageService.getUserPhone();
    final profileImage = await _storageService.getUserProfileImage();
    final isAdmin = await _storageService
        .getIsAdmin(); // 👈 2. Fetch admin status

    setState(() {
      _userName = name;
      _userPhone = phone;
      _userProfileImage = profileImage;
      _isAdmin = isAdmin; // 👈 3. Set admin status
    });
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
      body: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Unauthenticated) {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
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
                      onTap: () =>
                          Navigator.push(context, OrderHistoryScreen.route()),
                      id: 'order-history',
                      title: 'Order history',
                      icon: Iconsax.receipt,
                    ),
                    const Divider(height: 1, color: Color(0xFFE0E0E0)),
                    MenuItem(
                      onTap: () =>
                          Navigator.push(context, SupportScreen.route()),
                      id: 'help-center',
                      title: 'Help center',
                      icon: Iconsax.info_circle,
                    ),
                    const Divider(height: 1, color: Color(0xFFE0E0E0)),

                    // 👇 4. ONLY SHOW IF USER IS ADMIN 👇
                    if (_isAdmin) ...[
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
                        title: 'Admin Dashboard',
                        icon: Iconsax.chart_square,
                      ),
                      const Divider(height: 1, color: Color(0xFFE0E0E0)),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                child: LogoutButton(onTap: () => _handleLogout(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
