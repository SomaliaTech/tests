import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/product/domain/entities/product.dart';

class ProductInfo extends StatelessWidget {
  final Product product;
  final double? currentPrice; // ✅ ADDED: Dynamic variant price

  const ProductInfo({
    super.key,
    required this.product,
    this.currentPrice, // ✅ ADDED
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Use currentPrice if provided, otherwise fallback to base product.price
    final displayPrice = currentPrice ?? product.price;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "\$${displayPrice.toStringAsFixed(2)}", // ✅ USE DYNAMIC PRICE
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2ED573),
                ),
              ),
              // ✅ Optional: Show original price as strikethrough if variant price differs
              if (currentPrice != null && currentPrice! < product.price) ...[
                const SizedBox(width: 10),
                Text(
                  "\$${product.price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9CA3AF),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 15),
          const Divider(color: Color(0xFFEEEEEE), height: 1),
        ],
      ),
    );
  }
}
