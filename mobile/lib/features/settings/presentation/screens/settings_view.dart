import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/order_history/presentation/screens/order_history_screen.dart';
import 'package:mobile/features/settings/presentation/widgets/logout_button.dart';
import 'package:mobile/features/settings/presentation/widgets/menu_item.dart';
import 'package:mobile/features/settings/presentation/widgets/profile_section.dart';
import 'package:mobile/features/support/presentation/screens/support_screen.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  void _handleLogout(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      // iOS Style Dialog
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
                  // Handle logout logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logged out successfully'),
                      backgroundColor: Color(0xFF2ED573),
                    ),
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
      // Material Design Dialog
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
                  Navigator.pushAndRemoveUntil(
                    context,
                    OrderHistoryScreen.route(),
                    (route) => false,
                  );
                  // Handle logout logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logged out successfully'),
                      backgroundColor: Color(0xFF2ED573),
                    ),
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
      body: SafeArea(
        child: Column(
          children: [
            const ProfileSection(),
            const SizedBox(height: 10),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  MenuItem(
                    onTap: () {
                      Navigator.push(context, OrderHistoryScreen.route());
                    },
                    id: 'order-history',
                    title: 'Order history',
                    icon: Iconsax.receipt,
                  ),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  MenuItem(
                    onTap: () {
                      Navigator.push(context, SupportScreen.route());
                    },
                    id: 'help-center',
                    title: 'Help center',
                    icon: Iconsax.info_circle,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: LogoutButton(onTap: () => _handleLogout(context)),
            ),
          ],
        ),
      ),
    );
  }
}
