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
            builder: (context) => CategoryScreen(
              categoryId: category.id,
              categoryName: category.name,
            ),
          ),
        );
      },
      child: SizedBox(
        width: 75,
        child: Column(
          children: [
            // ✅ Show image if exists, otherwise show icon
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.09),
                shape: BoxShape.circle,
                // ✅ Add border if image exists
                border: category.hasIcon
                    ? Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 1.5,
                      )
                    : null,
              ),
              child: category.hasIcon
                  ? ClipOval(
                      child: Image.network(
                        category.iconUrl!,
                        fit: BoxFit.cover,
                        width: 65,
                        height: 65,
                        errorBuilder: (context, error, stackTrace) {
                          // ✅ Fallback to icon if image fails to load
                          return Icon(
                            _getIconForCategory(category.name),
                            size: 32,
                            color: Colors.green,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.green,
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Icon(
                      _getIconForCategory(category.name),
                      size: 32,
                      color: Colors.green,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'electronics':
        return Iconsax.mobile;
      case 'fashion':
        return Iconsax.clipboard_text;
      case 'home & living':
        return Iconsax.home;
      case 'beauty & personal care':
        return Iconsax.brush;
      case 'sports & outdoors':
        return Iconsax.blend;
      case 'health & wellness':
        return Iconsax.heart;
      case 'books & media':
        return Iconsax.book;
      case 'toys & games':
        return Iconsax.game;
      default:
        return Iconsax.category;
    }
  }
}
