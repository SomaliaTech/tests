// lib/core/common/widgets/checkout_order_summary.dart
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
  final double discountAmount; // ✅ NEW
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
    required this.discountAmount, // ✅ NEW
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                  color: const Color(0xFF2ED573).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.receipt_2,
                  color: Color(0xFF2ED573),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items list (for cart) or single product
          if (isCartCheckout && cartItems != null)
            ...cartItems!.map((item) => _buildCartItemRow(item))
          else if (product != null)
            _buildProductRow(),

          const Divider(height: 24),

          // Subtotal
          _buildSummaryRow(
            'Subtotal ($itemCount items)',
            '\$${subtotal.toStringAsFixed(2)}',
          ),

          // Delivery Fee
          _buildSummaryRow(
            'Delivery Fee',
            deliveryFee == 0 ? 'FREE' : '\$${deliveryFee.toStringAsFixed(2)}',
            valueColor: deliveryFee == 0 ? const Color(0xFF2ED573) : null,
          ),

          // ✅ Promo Discount (only show if > 0)
          if (discountAmount > 0)
            _buildSummaryRow(
              'Promo Discount',
              '- \$${discountAmount.toStringAsFixed(2)}',
              valueColor: const Color(0xFF2ED573),
            ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                '\$${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2ED573),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemRow(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 50,
                height: 50,
                color: Colors.grey[200],
                child: const Icon(Iconsax.image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.color != null || item.size != null)
                  Text(
                    [item.color, item.size].whereType<String>().join(' • '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} × \$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          // Price
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

  Widget _buildProductRow() {
    if (product == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product!.imageUrls.isNotEmpty ? product!.imageUrls.first : '',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 50,
                height: 50,
                color: Colors.grey[200],
                child: const Icon(Iconsax.image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product!.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (selectedColor != null || selectedSize != null)
                  Text(
                    [
                      selectedColor,
                      selectedSize,
                    ].whereType<String>().join(' • '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '$quantity × \$${unitPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          // Price
          Text(
            '\$${(unitPrice * quantity).toStringAsFixed(2)}',
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

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}
