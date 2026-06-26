import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/domain/entities/admin_product_entity.dart';

class ModernVariantCard extends StatelessWidget {
  final AdminProductVariantEntity variant;
  final VoidCallback? onDelete;
  final bool isNew;

  const ModernVariantCard({
    super.key,
    required this.variant,
    this.onDelete,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNew
              ? AppTheme.primaryColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
          width: isNew ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Color and Delete Button
            Row(
              children: [
                // Color Display
                if (variant.colorName != null) ...[
                  _buildColorCircle(variant.colorName!, variant.colorCode),
                  const SizedBox(width: 12),
                ],

                // Variant Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        variant.colorName ?? 'No Color',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (variant.sizeValue != null) ...[
                        const SizedBox(height: 6),
                        _buildSizeBadge(variant.sizeValue!),
                      ],
                    ],
                  ),
                ),

                // Delete Button
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Iconsax.trash,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Details Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  // SKU
                  Expanded(
                    child: _buildDetailItem(
                      icon: Iconsax.barcode,
                      label: 'SKU',
                      value: variant.sku ?? 'N/A',
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.withOpacity(0.2),
                  ),

                  // Stock
                  Expanded(
                    child: _buildDetailItem(
                      icon: Iconsax.box_1,
                      label: 'Stock',
                      value: '${variant.stock}',
                      valueColor: variant.stock > 10
                          ? AppTheme.primaryColor
                          : variant.stock > 0
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.withOpacity(0.2),
                  ),

                  // Price
                  Expanded(
                    child: _buildDetailItem(
                      icon: Iconsax.money_tick,
                      label: 'Price',
                      value: '\$${variant.price?.toStringAsFixed(2) ?? '0.00'}',
                      valueColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCircle(String colorName, String? colorCode) {
    final colorMap = {
      'red': '#FF0000',
      'blue': '#0000FF',
      'green': '#00FF00',
      'yellow': '#FFFF00',
      'black': '#000000',
      'white': '#FFFFFF',
      'gray': '#808080',
      'grey': '#808080',
      'orange': '#FFA500',
      'purple': '#800080',
      'pink': '#FFC0CB',
      'brown': '#A52A2A',
    };

    final colorHex =
        colorCode ?? colorMap[colorName.toLowerCase()] ?? '#CCCCCC';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _hexToColor(colorHex),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: Shows only the size value
  Widget _buildSizeBadge(String sizeValue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      child: Text(
        sizeValue.toUpperCase(),
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
