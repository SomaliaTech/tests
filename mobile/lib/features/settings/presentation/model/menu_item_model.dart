import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class MenuItem {
  final String id;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const MenuItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.onTap,
  });
}
