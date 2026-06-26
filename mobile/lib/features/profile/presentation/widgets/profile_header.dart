import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ProfileHeader extends StatelessWidget {
  final VoidCallback onBackPressed;

  const ProfileHeader({super.key, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onBackPressed,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Iconsax.arrow_left, color: Color(0xFF333333)),
                ),
              ),
              const Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 44), // Balance the back button
            ],
          ),
        ),
      ),
    );
  }
}
