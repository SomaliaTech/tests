import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/cart/domain/entities/cart_item.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final bool showStockWarning; // ✅ Added

  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    this.showStockWarning = false, // ✅ Default false
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            showStockWarning // ✅ Red border for stock issues
            ? Border.all(
                color: Colors.orange.withValues(alpha: 0.5),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Stock warning indicator
          if (showStockWarning)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.warning_2, size: 12, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    !item.inStock
                        ? 'Out of stock'
                        : 'Exceeds stock (max: ${item.maxStock})',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
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
                    // ✅ Show stock info
                    if (item.maxStock > 0 && item.maxStock < 999)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Stock: ${item.maxStock}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Quantity Controls
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              // Minus Button
                              GestureDetector(
                                onTap: item.canDecrease
                                    ? () {
                                        HapticFeedback.lightImpact();
                                        onDecrement();
                                      }
                                    : null,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Iconsax.minus,
                                    size: 16,
                                    color: item.canDecrease
                                        ? const Color(0xFF333333)
                                        : Colors.grey[400],
                                  ),
                                ),
                              ),
                              // Quantity Display
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
                              // Plus Button
                              GestureDetector(
                                onTap: () {
                                  print('🔵 Plus button tapped!');
                                  print('🔵 canIncrease: ${item.canIncrease}');
                                  print('🔵 quantity: ${item.quantity}');
                                  print('🔵 maxStock: ${item.maxStock}');
                                  print('🔵 inStock: ${item.inStock}');

                                  if (item.canIncrease) {
                                    HapticFeedback.lightImpact();
                                    onIncrement();
                                  } else {
                                    HapticFeedback.heavyImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          item.maxStock >= 999
                                              ? 'Cannot increase quantity'
                                              : 'Maximum stock reached (${item.maxStock})',
                                        ),
                                        backgroundColor: Colors.orange,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Iconsax.add,
                                    size: 16,
                                    color: item.canIncrease
                                        ? const Color(0xFF333333)
                                        : Colors.grey[400],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Remove Button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            onRemove();
                          },
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
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: Colors.grey[200],
      child: const Icon(Iconsax.image, color: Colors.grey, size: 32),
    );
  }
}
