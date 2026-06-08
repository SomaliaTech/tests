import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ProductHeader extends StatelessWidget {
  final String productName;

  const ProductHeader({super.key, required this.productName});

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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2ED573),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Iconsax.arrow_left, color: Colors.white),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Wishlist Button
            ],
          ),
        ),
      ),
    );
  }
}
