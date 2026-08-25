// lib/features/admin/presentation/widgets/banner_form/banner_flash_sale_section.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_section_card.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_text_field.dart';
import 'package:mobile/features/admin/presentation/widgets/banner_form/banner_switch.dart';
import 'package:mobile/features/product/data/models/banner_form_data.dart';

class BannerFlashSaleSection extends StatelessWidget {
  final BannerFormData formData;
  final VoidCallback onChanged;

  const BannerFlashSaleSection({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BannerSectionCard(
      title: 'Flash Sale Settings',
      icon: Iconsax.flash,
      children: [
        // Enable Flash Sale
        BannerSwitch(
          label: 'Enable Flash Sale',
          value: formData.isFlashSale,
          onChanged: (value) {
            formData.isFlashSale = value;
            onChanged();
          },
        ),

        if (formData.isFlashSale) ...[
          const SizedBox(height: 16),

          // Flash Sale Price
          BannerTextField(
            label: 'Flash Sale Price (\$)',
            hint: '19.99',
            icon: Iconsax.dollar_circle,
            keyboardType: TextInputType.number,
            initialValue: formData.flashSalePrice?.toString(),
            onChanged: (value) {
              formData.flashSalePrice = double.tryParse(value);
              onChanged();
            },
          ),
          const SizedBox(height: 16),

          // Quantity
          BannerTextField(
            label: 'Flash Sale Quantity',
            hint: '100',
            icon: Iconsax.box,
            keyboardType: TextInputType.number,
            initialValue: formData.flashSaleQuantity?.toString(),
            onChanged: (value) {
              formData.flashSaleQuantity = int.tryParse(value);
              onChanged();
            },
          ),
          const SizedBox(height: 16),

          // Time Range
          _buildTimeRangeSection(context),
        ],
      ],
    );
  }

  Widget _buildTimeRangeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Flash Sale Period',
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
              child: _buildDateTimePicker(
                context: context,
                label: 'Start Time',
                selectedDate: formData.flashSaleStartTime,
                onSelected: (dateTime) {
                  formData.flashSaleStartTime = dateTime;
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateTimePicker(
                context: context,
                label: 'End Time',
                selectedDate: formData.flashSaleEndTime,
                onSelected: (dateTime) {
                  formData.flashSaleEndTime = dateTime;
                  onChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ✅ FIXED: Countdown Preview with better responsive handling
        if (formData.flashSaleEndTime != null) _buildCountdownPreview(),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required BuildContext context,
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (date != null) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(selectedDate ?? DateTime.now()),
          );
          if (time != null) {
            onSelected(
              DateTime(date.year, date.month, date.day, time.hour, time.minute),
            );
          }
        }
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
            const Icon(Iconsax.clock, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedDate != null
                    ? '${selectedDate.day}/${selectedDate.month} ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}'
                    : label,
                style: TextStyle(
                  color: selectedDate != null
                      ? const Color(0xFF1F2937)
                      : Colors.grey,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ OPTIMIZED: Better responsive countdown preview
  Widget _buildCountdownPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // ✅ If screen is too narrow, stack vertically
          if (constraints.maxWidth < 360) {
            return Column(
              children: [
                const Row(
                  children: [
                    Icon(Iconsax.timer_1, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Countdown Timer Preview:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimerBox('24'),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        ':',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _buildTimerBox('59'),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        ':',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _buildTimerBox('59'),
                  ],
                ),
              ],
            );
          }

          // ✅ Default horizontal layout for wider screens
          return Row(
            children: [
              const Icon(Iconsax.timer_1, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Countdown Timer Preview:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTimerBox('24'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _buildTimerBox('59'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _buildTimerBox('59'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimerBox(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
