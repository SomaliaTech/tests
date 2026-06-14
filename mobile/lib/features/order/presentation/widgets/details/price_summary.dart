import 'package:flutter/material.dart';

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
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _buildPriceRow('Shipping Fee', '\$${shippingFee.toStringAsFixed(2)}'),
          if (discount > 0) ...[
            const SizedBox(height: 10),
            _buildPriceRow('Discount', '-\$${discount.toStringAsFixed(2)}'),
          ],
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFEEEEEE), height: 1),
          const SizedBox(height: 10),
          _buildPriceRow(
            'Total',
            '\$${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFF333333) : const Color(0xFF666666),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFF2ED573) : const Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}
