import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/cart/domain/entities/cart_item.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🚀 FIXED: Robust Image Loading
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder();
                    },
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2ED573),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: onDecrement,
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              child: Icon(
                                Iconsax.minus,
                                size: 16,
                                color: item.quantity == 1
                                    ? Colors.grey[400]
                                    : const Color(0xFF33),
                              ),
                            ),
                          ),
                          Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              item.quantity.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: onIncrement,
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              child: Icon(
                                Iconsax.add,
                                size: 16,
                                color: !item.inStock
                                    ? Colors.grey[400]
                                    : const Color(0xFF3333),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Iconsax.trash,
                          size: 18,
                          color: Color(0xFFFF4757),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for missing images
  Widget _buildPlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: Colors.grey[200],
      child: const Icon(Iconsax.image, color: Colors.grey, size: 32),
    );
  }
}
