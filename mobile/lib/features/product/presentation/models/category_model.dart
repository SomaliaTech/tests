import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class Category {
  final int id;
  final String name;
  final IconData icon;
  final Color color;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

final List<Category> categories = [
  Category(
    id: 1,
    name: "Events",
    icon: Iconsax.gift,
    color: const Color(0xFFFF4757),
  ),
  Category(
    id: 2,
    name: "Electronics",
    icon: Iconsax.watch,
    color: const Color(0xFFFFA502),
  ),
  Category(
    id: 3,
    name: "Home Kitchen",
    icon: Iconsax.home,
    color: const Color(0xFF2ED573),
  ),
  Category(
    id: 4,
    name: "Cosmetics",
    icon: Iconsax.color_swatch,
    color: const Color(0xFFFF6B81),
  ),
  Category(
    id: 5,
    name: "Fashion",
    icon: Iconsax.sort,
    color: const Color(0xFF70A1FF),
  ),
  Category(
    id: 6,
    name: "Jirdhis",
    icon: Iconsax.activity,
    color: const Color(0xFF5352ED),
  ),
  Category(
    id: 7,
    name: "Caruur",
    icon: Iconsax.activity,
    color: const Color(0xFFFF7F50),
  ),
  Category(
    id: 8,
    name: "Supplements",
    icon: Iconsax.ship,
    color: const Color(0xFF3742FA),
  ),
];
