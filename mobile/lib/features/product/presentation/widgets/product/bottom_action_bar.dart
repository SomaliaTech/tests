import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class BottomActionBar extends StatelessWidget {
  final VoidCallback onFavoriteTap;
  final VoidCallback onBuyNowTap;
  final bool isInWishlist;
  final String productName;

  const BottomActionBar({
    super.key,
    required this.onFavoriteTap,
    required this.onBuyNowTap,
    required this.productName,
    required this.isInWishlist,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(15),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2ED573), width: 1),
              ),
              child: IconButton(
                onPressed: onFavoriteTap,
                icon: Icon(
                  isInWishlist ? Iconsax.heart5 : Iconsax.heart,
                  color: isInWishlist ? Colors.red : Colors.black87,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton(
                onPressed: onBuyNowTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ED573),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "BUY NOW",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
