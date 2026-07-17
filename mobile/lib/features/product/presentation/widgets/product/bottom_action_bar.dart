import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

class BottomActionBar extends StatelessWidget {
  final String productName;
  final bool isInWishlist;
  final bool isInStock; // ✅ Added
  final VoidCallback onFavoriteTap;
  final VoidCallback onAddToCartTap;
  final VoidCallback onBuyNowTap;
  final VoidCallback? onChatTap;
  final bool isAdmin;

  const BottomActionBar({
    super.key,
    required this.productName,
    required this.isInWishlist,
    this.isInStock = true, // ✅ Added with default true
    required this.onFavoriteTap,
    required this.onAddToCartTap,
    required this.onBuyNowTap,
    this.onChatTap,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Favorite Button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onFavoriteTap();
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isInWishlist
                      ? const Color(0xFF2ED573).withValues(alpha: 0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isInWishlist
                        ? const Color(0xFF2ED573)
                        : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isInWishlist ? Iconsax.heart5 : Iconsax.heart,
                  color: isInWishlist
                      ? const Color(0xFF2ED573)
                      : Colors.grey[600],
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Add to Cart Button
            Expanded(
              flex: onChatTap != null && isAdmin ? 1 : 2,
              child: GestureDetector(
                onTap:
                    isInStock // ✅ Disable if out of stock
                    ? () {
                        HapticFeedback.mediumImpact();
                        onAddToCartTap();
                      }
                    : null,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color:
                        isInStock // ✅ Grey if out of stock
                        ? const Color(0xFF2ED573)
                        : Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.shopping_cart,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isInStock
                            ? 'Add to Cart'
                            : 'Out of Stock', // ✅ Show status
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Buy Now Button
            Expanded(
              flex: onChatTap != null && isAdmin ? 1 : 2,
              child: GestureDetector(
                onTap:
                    isInStock // ✅ Disable if out of stock
                    ? () {
                        HapticFeedback.mediumImpact();
                        onBuyNowTap();
                      }
                    : null,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient:
                        isInStock // ✅ Grey if out of stock
                        ? const LinearGradient(
                            colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isInStock
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF2ED573,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.flash, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Buy Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
