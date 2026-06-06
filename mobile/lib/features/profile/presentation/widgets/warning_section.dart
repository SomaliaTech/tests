import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:iconsax/iconsax.dart';

class WarningSection extends StatelessWidget {
  final VoidCallback onWhatsAppPressed;
  final VoidCallback onDeletePressed;

  const WarningSection({
    super.key,
    required this.onWhatsAppPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          const Text(
            'ACCOUNT DELETION WARNING!',
            style: TextStyle(
              color: Color(0xFFFF4757),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Delete account? All data will be lost. Contact us at',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onWhatsAppPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Iconsax.message_circle, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    '+252 61 998 8338 (WhatsApp)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: onDeletePressed,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Iconsax.trash, size: 18, color: Color(0xFFFF4757)),
                SizedBox(width: 8),
                Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Color(0xFFFF4757),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
