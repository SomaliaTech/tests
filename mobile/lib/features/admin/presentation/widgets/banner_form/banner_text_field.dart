// lib/features/admin/presentation/widgets/banner_form/banner_text_field.dart
import 'package:flutter/material.dart';
import 'package:mobile/core/theme/theme.dart';

class BannerTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final String? initialValue;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final Function(String) onChanged;

  const BannerTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.initialValue,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextFormField(
            initialValue: initialValue,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: Color(0xFF1F2937)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
