import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class TabButton extends StatelessWidget {
  final bool isActive;
  final String title;
  final VoidCallback onTap;

  const TabButton({
    super.key,
    required this.isActive,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // flex: 1,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2ED573) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.receipt,
              size: 18,
              color: isActive ? Colors.white : const Color(0xFF2ED573),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF2ED573),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
