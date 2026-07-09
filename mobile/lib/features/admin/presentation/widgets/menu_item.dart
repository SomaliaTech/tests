import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class MenuItem extends StatelessWidget {
  final String id;
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Widget? trailing;
  final bool showArrow;

  const MenuItem({
    super.key,
    required this.id,
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.trailing,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.grey.withOpacity(0.1),
        highlightColor: Colors.grey.withOpacity(0.05),
        child: Container(
          // ✅ CRITICAL: Provide bounded width
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (iconColor ?? const Color(0xFF2ED573)).withOpacity(
                    0.1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? const Color(0xFF2ED573),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Title - ✅ Expanded to take available space
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),

              // Trailing or Arrow
              if (trailing != null)
                trailing!
              else if (showArrow)
                const Icon(Iconsax.arrow_right_3, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
