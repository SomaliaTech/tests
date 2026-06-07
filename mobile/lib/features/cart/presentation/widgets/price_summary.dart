import 'package:flutter/material.dart';
import 'price_row.dart';

class PriceSummary extends StatelessWidget {
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double total;

  const PriceSummary({
    super.key,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final freeShippingAmount = 50 - subtotal;
    final showFreeShippingMessage = shippingFee > 0 && freeShippingAmount > 0;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          PriceRow(
            label: 'Subtotal',
            value: '\$${subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          PriceRow(
            label: 'Shipping',
            value: shippingFee == 0
                ? 'FREE'
                : '\$${shippingFee.toStringAsFixed(2)}',
          ),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            PriceRow(
              label: 'Discount',
              value: '-\$${discount.toStringAsFixed(2)}',
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          PriceRow(
            label: 'Total',
            value: '\$${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
          if (showFreeShippingMessage) ...[
            const SizedBox(height: 10),
            Text(
              'Add \$${freeShippingAmount.toStringAsFixed(2)} more for FREE shipping',
              style: const TextStyle(fontSize: 13, color: Color(0xFFFFA502)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
