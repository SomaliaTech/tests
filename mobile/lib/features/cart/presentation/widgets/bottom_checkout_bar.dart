import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class BottomCheckoutBar extends StatelessWidget {
  final int itemCount;
  final double total;
  final bool isEnabled;
  final VoidCallback? onCheckout; // ✅ Make nullable

  const BottomCheckoutBar({
    super.key,
    required this.itemCount,
    required this.total,
    required this.isEnabled,
    required this.onCheckout, // ✅ Can be null now
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total ($itemCount items)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2ED573),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: (isEnabled && onCheckout != null) ? onCheckout : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: (isEnabled && onCheckout != null)
                      ? const Color(0xFF2ED573)
                      : const Color(0xFFA8E6CF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      onCheckout != null
                          ? 'Proceed to Checkout'
                          : 'Fix Stock Issues to Continue',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Iconsax.arrow_right_1,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
