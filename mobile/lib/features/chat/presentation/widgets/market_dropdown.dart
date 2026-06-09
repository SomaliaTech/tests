import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/profile/data/models/profile_model.dart';
import 'package:mobile/features/profile/domain/entities/market.dart';

class MarketDropdown extends StatelessWidget {
  final bool isOpen;
  final Market? selectedMarket;
  final List<Market> markets;
  final ValueChanged<Market> onMarketSelected;
  final VoidCallback onClose;

  const MarketDropdown({
    super.key,
    required this.isOpen,
    required this.selectedMarket,
    required this.markets,
    required this.onMarketSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Select Market',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                ...markets.map(
                  (market) => GestureDetector(
                    onTap: () => onMarketSelected(market),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selectedMarket == market
                                ? const Color(0xFF2ED573)
                                : const Color(0xFFEEEEEE),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            market.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              color: selectedMarket == market
                                  ? const Color(0xFF2ED573)
                                  : const Color(0xFF333333),
                              fontWeight: selectedMarket == market
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          if (selectedMarket == market)
                            const Icon(
                              Iconsax.tick_circle,
                              size: 20,
                              color: Color(0xFF2ED573),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
