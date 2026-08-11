// lib/features/product/presentation/widgets/home/discount_badge.dart

import 'package:flutter/material.dart';

class DiscountBadge extends StatelessWidget {
  final double? percentage;
  final double? amount;

  const DiscountBadge({super.key, this.percentage, this.amount});

  @override
  Widget build(BuildContext context) {
    String text;
    if (percentage != null) {
      text = '${percentage!.toInt()}% OFF';
    } else if (amount != null) {
      text = '\$${amount!.toStringAsFixed(2)} OFF';
    } else {
      text = 'SALE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF4757), Color(0xFFFF6B81)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.discount, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
