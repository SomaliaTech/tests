import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/profile/domain/entities/market.dart';
import '../../domain/entities/profile.dart';

class ProfileForm extends StatelessWidget {
  final Profile profile;
  final Market? selectedMarket;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onMarketTap;
  final VoidCallback onUpdatePressed;
  final bool isUpdating;

  const ProfileForm({
    super.key,
    required this.profile,
    this.selectedMarket,
    required this.onNameChanged,
    required this.onMarketTap,
    required this.onUpdatePressed,
    required this.isUpdating,
  });

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: profile.name);
    final emailController = TextEditingController(text: profile.email ?? '');
    final phoneController = TextEditingController(text: profile.phoneNumber);

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Column(
        children: [
          // Phone (Read-only)
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: TextField(
              controller: phoneController,
              enabled: false,
              style: const TextStyle(color: Color(0xFF666666)),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFC8F6DC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFC8F6DC)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // Name
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: TextField(
              controller: nameController,
              onChanged: onNameChanged,
              decoration: InputDecoration(
                hintText: 'Full Name',
                hintStyle: const TextStyle(color: Color(0xFF999999)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFC8F6DC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFC8F6DC)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // Email
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: TextField(
              controller: emailController,
              onChanged: (value) {},
              decoration: InputDecoration(
                hintText: 'Email (optional)',
                hintStyle: const TextStyle(color: Color(0xFF999999)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFC8F6DC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFC8F6DC)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // Market Selector
          GestureDetector(
            onTap: onMarketTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFC8F6DC)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedMarket?.displayName ??
                        profile.marketName ??
                        'Select market',
                    style: TextStyle(
                      color:
                          (selectedMarket != null || profile.marketName != null)
                          ? const Color(0xFF333333)
                          : const Color(0xFF999999),
                      fontSize: 15,
                    ),
                  ),
                  const Icon(
                    Iconsax.arrow_down_1,
                    size: 20,
                    color: Color(0xFF999999),
                  ),
                ],
              ),
            ),
          ),

          // Update Button
          GestureDetector(
            onTap: isUpdating ? null : onUpdatePressed,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isUpdating
                    ? const Color(0xFFA8E6CF)
                    : const Color(0xFF2ED573),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  isUpdating ? 'UPDATING...' : 'UPDATE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
