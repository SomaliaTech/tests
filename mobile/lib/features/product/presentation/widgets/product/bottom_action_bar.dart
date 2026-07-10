import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

class BottomActionBar extends StatelessWidget {
  final String productName;
  final bool isInWishlist;
  final VoidCallback onFavoriteTap;
  final VoidCallback onAddToCartTap;
  final VoidCallback onBuyNowTap;
  final VoidCallback? onChatTap; // ✅ Optional chat callback
  final bool isAdmin;

  const BottomActionBar({
    super.key,
    required this.productName,
    required this.isInWishlist,
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
            // ✅ Heart (Favorite) Button
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

            // ✅ Chat Button (Optional)
            if (onChatTap != null && isAdmin) ...[
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onChatTap!();
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[300]!, width: 1.5),
                  ),
                  child: Icon(
                    Iconsax.message,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Add to Cart Button (flexible)
            Expanded(
              flex: onChatTap != null && isAdmin ? 1 : 2,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onAddToCartTap();
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ED573),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.shopping_cart,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Add to Cart',
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
            const SizedBox(width: 8),

            // Buy Now Button (flexible)
            Expanded(
              flex: onChatTap != null && isAdmin ? 1 : 2,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onBuyNowTap();
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2ED573).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
