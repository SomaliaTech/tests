// lib/features/product/presentation/widgets/checkout/checkout_market_section.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/admin/domain/entities/market_entity.dart';

class CheckoutMarketSection extends StatelessWidget {
  final List<MarketEntity> availableMarkets;
  final MarketEntity? selectedMarket;
  final ValueChanged<MarketEntity?> onMarketChanged;
  final double deliveryFee;
  final int itemCount;

  const CheckoutMarketSection({
    super.key,
    required this.availableMarkets,
    required this.selectedMarket,
    required this.onMarketChanged,
    required this.deliveryFee,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSectionCard(
      icon: Iconsax.buildings,
      iconColor: const Color(0xFF2ED573),
      title: 'Suuqa Bixinta', // Delivery Market
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MarketEntity>(
              isExpanded: true,
              value: selectedMarket,
              hint: const Text('Dooro suuq'), // Select market
              items: availableMarkets.map((market) {
                return DropdownMenuItem(
                  value: market,
                  child: Text(
                    market.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
              onChanged: onMarketChanged,
            ),
          ),
        ),
        if (selectedMarket != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  icon: Iconsax.clock,
                  label: 'Wakhtiga', // Est. Time
                  value: '${selectedMarket!.deliveryEstimationMinutes} min',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoChip(
                  icon: Iconsax.money,
                  label: 'Bixinta', // Delivery
                  value: deliveryFee == 0.0
                      ? 'BILAASH'
                      : '\$${deliveryFee.toStringAsFixed(2)}', // FREE
                  color: deliveryFee == 0.0
                      ? const Color(0xFF2ED573)
                      : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ],
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

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
