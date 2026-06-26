import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'chat_button.dart';

class BottomActionBar extends StatelessWidget {
  final String productName;
  final bool isInWishlist;
  final VoidCallback onFavoriteTap;
  final VoidCallback onAddToCartTap;
  final VoidCallback onBuyNowTap;
  final bool isAdmin;

  const BottomActionBar({
    super.key,
    required this.productName,
    required this.isInWishlist,
    required this.onFavoriteTap,
    required this.onAddToCartTap,
    required this.onBuyNowTap,
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
            // Chat with Admin Button - Only show for non-admin users
            if (!isAdmin) ...[
              const ChatWithAdminButton(),
              const SizedBox(width: 8),
            ],

            // Favorite Button with haptic feedback
            GestureDetector(
              onTap: () {
                // Light haptic for toggle actions
                HapticFeedback.lightImpact();
                onFavoriteTap();
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isInWishlist
                      ? const Color(0xFFFF4757).withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isInWishlist
                        ? const Color(0xFFFF4757)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Icon(
                  isInWishlist ? Iconsax.heart5 : Iconsax.heart,
                  color: isInWishlist
                      ? const Color(0xFFFF4757)
                      : Colors.grey.shade600,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Add to Cart Button with haptic feedback
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Medium haptic for primary action
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
                        size: 15,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Add to Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Buy Now Button with haptic feedback
            // Buy Now Button - Use gradient or different color
            Expanded(
              child: GestureDetector(
                onTap: onBuyNowTap,
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
                      Icon(Iconsax.flash, color: Colors.white, size: 15),
                      SizedBox(width: 8),
                      Text(
                        'Buy Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
