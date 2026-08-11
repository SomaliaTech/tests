// lib/features/admin/presentation/widgets/banner_form/banner_discount_section.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_section_card.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_text_field.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_switch.dart';
import 'package:mobile/features/product/data/models/banner_form_data.dart';
// lib/features/admin/presentation/widgets/banner_form/banner_discount_section.dart

class BannerDiscountSection extends StatelessWidget {
  final BannerFormData formData;
  final VoidCallback onChanged;

  const BannerDiscountSection({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BannerSectionCard(
      title: 'Discount Settings',
      icon: Iconsax.discount_shape,
      children: [
        // Enable Discount
        BannerSwitch(
          label: 'Enable Discount',
          value: formData.hasDiscount,
          onChanged: (value) {
            formData.hasDiscount = value;
            onChanged();
          },
        ),

        if (formData.hasDiscount) ...[
          const SizedBox(height: 16),
          _buildDiscountTypeSelector(),
          const SizedBox(height: 16),

          // Discount Value
          if (formData.discountPercentage != null)
            BannerTextField(
              label: 'Discount Percentage (%)',
              hint: '50',
              icon: Iconsax.percentage_circle,
              keyboardType: TextInputType.number,
              initialValue: formData.discountPercentage?.toString(),
              onChanged: (value) {
                formData.discountPercentage = double.tryParse(value);
                formData.discountAmount = null;
                onChanged();
              },
            )
          else
            BannerTextField(
              label: 'Discount Amount (\$)',
              hint: '25.00',
              icon: Iconsax.money,
              keyboardType: TextInputType.number,
              initialValue: formData.discountAmount?.toString(),
              onChanged: (value) {
                formData.discountAmount = double.tryParse(value);
                formData.discountPercentage = null;
                onChanged();
              },
            ),
          const SizedBox(height: 16),

          // Discount Code
          BannerTextField(
            label: 'Discount Code',
            hint: 'SUMMER50',
            icon: Iconsax.code,
            initialValue: formData.discountCode,
            onChanged: (value) {
              formData.discountCode = value;
              onChanged();
            },
          ),
          const SizedBox(height: 16),

          // ✅ FIX: Pass context to the date range section
          _buildDateRangeSection(context),
        ],
      ],
    );
  }

  Widget _buildDiscountTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                formData.discountPercentage = 50;
                formData.discountAmount = null;
                onChanged();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: formData.discountPercentage != null
                      ? const Color(0xFF2ED573)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.percentage_circle,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Percentage',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                formData.discountAmount = 25;
                formData.discountPercentage = null;
                onChanged();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: formData.discountAmount != null
                      ? const Color(0xFF2ED573)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.dollar_circle, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Fixed Amount',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIX: Accept BuildContext as parameter
  Widget _buildDateRangeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Discount Period',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(
                context: context, // ✅ Pass context
                label: 'Start Date',
                selectedDate: formData.discountStartDate,
                onDateSelected: (date) {
                  formData.discountStartDate = date;
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDatePicker(
                context: context, // ✅ Pass context
                label: 'End Date',
                selectedDate: formData.discountEndDate,
                onDateSelected: (date) {
                  formData.discountEndDate = date;
                  onChanged();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ FIX: Accept BuildContext as parameter
  Widget _buildDatePicker({
    required BuildContext context, // ✅ Add context parameter
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context, // ✅ Now context is available
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) onDateSelected(date);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(Iconsax.calendar, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedDate != null
                    ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                    : label,
                style: TextStyle(
                  color: selectedDate != null
                      ? const Color(0xFF1F2937)
                      : Colors.grey,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
