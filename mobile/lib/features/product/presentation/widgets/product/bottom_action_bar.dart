import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

class BottomActionBar extends StatelessWidget {
  final String productName;
  final double? currentPrice; // ✅ ADDED: Dynamic variant price
  final bool isInWishlist;
  final bool isInStock;
  final VoidCallback onFavoriteTap;
  final VoidCallback onAddToCartTap;
  final VoidCallback onBuyNowTap;
  final VoidCallback? onChatTap;
  final bool isAdmin;

  const BottomActionBar({
    super.key,
    required this.productName,
    this.currentPrice, // ✅ ADDED
    required this.isInWishlist,
    this.isInStock = true,
    required this.onFavoriteTap,
    required this.onAddToCartTap,
    required this.onBuyNowTap,
    this.onChatTap,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ DYNAMIC PRICE DISPLAY
            if (currentPrice != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 4),
                child: Row(
                  children: [
                    Text(
                      'Price: ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '\$${currentPrice!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF2ED573),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

            Row(
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
                    onTap: isInStock
                        ? () {
                            HapticFeedback.mediumImpact();
                            onAddToCartTap();
                          }
                        : null,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: isInStock
                            ? const Color(0xFF2ED573)
                            : Colors.grey[400],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Iconsax.shopping_cart,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isInStock ? 'Add to Cart' : 'Out of Stock',
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
                    onTap: isInStock
                        ? () {
                            HapticFeedback.mediumImpact();
                            onBuyNowTap();
                          }
                        : null,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: isInStock
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
          ],
        ),
      ),
    );
  }
}
