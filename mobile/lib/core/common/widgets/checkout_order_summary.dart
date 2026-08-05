// lib/features/product/presentation/widgets/checkout/checkout_order_summary.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/cart/domain/entities/cart_item.dart';
import 'package:mobile/features/product/domain/entities/product.dart';

class CheckoutOrderSummary extends StatelessWidget {
  final bool isCartCheckout;
  final List<CartItem>? cartItems;
  final Product? product;
  final String? selectedColor;
  final String? selectedSize;
  final int quantity;
  final double unitPrice;
  final int itemCount;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;

  const CheckoutOrderSummary({
    super.key,
    required this.isCartCheckout,
    this.cartItems,
    this.product,
    this.selectedColor,
    this.selectedSize,
    required this.quantity,
    required this.unitPrice,
    required this.itemCount,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSectionCard(
      icon: Iconsax.shopping_bag,
      iconColor: const Color(0xFF2ED573),
      title: 'Soo Koobida Dalabka', // Order Summary
      children: [
        const SizedBox(height: 12),
        if (isCartCheckout && cartItems != null)
          ...cartItems!.map(_buildCartItemRow)
        else if (product != null)
          _buildSingleProductRow(),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        _buildSummaryRow(
          'Alaabaha ($itemCount)',
          '\$${subtotal.toStringAsFixed(2)}',
        ), // Items
        if (deliveryFee > 0)
          _buildSummaryRow(
            'Kharashka Bixinta',
            '\$${deliveryFee.toStringAsFixed(2)}',
          ) // Delivery Fee
        else
          _buildSummaryRow(
            'Bixinta',
            'BILAASH',
            color: const Color(0xFF2ED573),
          ), // Delivery - FREE
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 8),
        _buildSummaryRow(
          'Wadarta Guud', // Total
          '\$${totalAmount.toStringAsFixed(2)}',
          isTotal: true,
          color: const Color(0xFF2ED573),
        ),
      ],
    );
  }

  Widget _buildSingleProductRow() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: product!.imageUrls.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    product!.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Iconsax.image, color: Color(0xFF9CA3AF)),
                  ),
                )
              : const Icon(Iconsax.box_1, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product!.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (selectedColor != null || selectedSize != null)
                Text(
                  '${selectedColor ?? ''} ${selectedSize ?? ''}'.trim(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${unitPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              'Tiro: $quantity', // Qty
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCartItemRow(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: item.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Iconsax.image,
                        color: Color(0xFF9CA3AF),
                        size: 20,
                      ),
                    ),
                  )
                : const Icon(Iconsax.box_1, color: Color(0xFF9CA3AF), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.color ?? ''} ${item.size ?? ''} x${item.quantity}'
                      .trim(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${item.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: color ?? const Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: color ?? const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}
