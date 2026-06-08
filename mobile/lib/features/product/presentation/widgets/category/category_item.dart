import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/product/domain/entities/category.dart';
import 'package:mobile/features/product/presentation/screens/category_screen.dart';

class CategoryItem extends StatelessWidget {
  final Category category;

  const CategoryItem({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryProductsScreen(
              categoryId: category.id,
              categoryName: category.name,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForCategory(category.name),
              size: 32,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _truncateName(category.name),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _truncateName(String name) {
    if (name.length > 12) {
      return '${name.substring(0, 10)}...';
    }
    return name;
  }

  IconData _getIconForCategory(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('electronic')) return Iconsax.mobile;
    if (lowerName.contains('fashion')) return Iconsax.clipboard_text;
    if (lowerName.contains('home')) return Iconsax.home;
    if (lowerName.contains('beauty')) return Iconsax.brush;
    if (lowerName.contains('sport')) return Iconsax.activity;
    if (lowerName.contains('health')) return Iconsax.health;
    if (lowerName.contains('book')) return Iconsax.book;
    if (lowerName.contains('toy')) return Iconsax.game;
    return Iconsax.category;
  }
}
