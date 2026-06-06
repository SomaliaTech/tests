import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class MenuItem extends StatelessWidget {
  final String id;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const MenuItem({
    super.key,
    required this.id,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, size: 24, color: const Color(0xFF333333)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF333333),
        ),
      ),
      trailing: const Icon(
        Iconsax.arrow_right_3,
        size: 24,
        color: Color(0xFF333333),
      ),
      onTap: onTap,
    );
  }
}
