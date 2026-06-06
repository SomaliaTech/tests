import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CategoryHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBackPressed;
  final VoidCallback onCartPressed;
  final int cartItemCount;

  const CategoryHeader({
    super.key,
    required this.title,
    required this.onBackPressed,
    required this.onCartPressed,
    this.cartItemCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBackPressed,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: const Icon(
                    Iconsax.arrow_left,
                    size: 24,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onCartPressed,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Stack(
                    children: [
                      const Icon(
                        Iconsax.shopping_cart,
                        size: 24,
                        color: Color(0xFF2ED573),
                      ),
                      if (cartItemCount > 0)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF4757),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                cartItemCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
