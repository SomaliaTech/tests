import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'package:mobile/features/product/presentation/screens/product_detail_screen.dart';
import 'package:mobile/features/product/presentation/widgets/product/product_model.dart';

class ProductsGrid extends StatelessWidget {
  final List<Product> prodcut;

  const ProductsGrid({super.key, required this.prodcut});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 15,
          mainAxisExtent: 250, // 🎯 Reduced from 300 to match the medium scale
        ),
        itemCount: prodcut.length,
        itemBuilder: (context, index) {
          return _ProductCard(product: prodcut[index]);
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          ProductDetailScreen.route(product.id.toString()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Product Image Container
            SizedBox(
              height: 160,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                child: Image.network(
                  product.images.first,
                  height: 160, // 🎯 Matches the parent height
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Iconsax.image,
                        size: 40, // Scaled down icon slightly to fit the frame
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Content Area
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize:
                            13, // Slightly adjusted text for cleaner medium UI
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                        height: 1.2,
                      ),
                    ),

                    const Divider(height: 4),

                    Text(
                      "\$${product.price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 16, // Cleaned up scale to match text size
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2ED573),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
