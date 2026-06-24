import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/chat/models%2005-31-33-117/profile_model.dart';
import 'package:mobile/features/profile/data/models/profile_model.dart';

class ProfileForm extends StatelessWidget {
  final ProfileData profile;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onMarketTap;
  final VoidCallback onUpdatePressed;
  final bool isUpdating;

  const ProfileForm({
    super.key,
    required this.profile,
    required this.onNameChanged,
    required this.onMarketTap,
    required this.onUpdatePressed,

    required this.isUpdating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Column(
        children: [
          // Phone (Read-only)
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: TextField(
              controller: TextEditingController(text: profile.phone),
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
              // initialValue: profile.name,
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
                    profile.market?.displayName ?? 'Select market',
                    style: TextStyle(
                      color: profile.market != null
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

          // Invite Friends Button
        ],
      ),
    );
  }
}
