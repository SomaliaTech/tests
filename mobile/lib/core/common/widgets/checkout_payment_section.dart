// lib/features/product/presentation/widgets/checkout/checkout_payment_section.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/common/widgets/shared/payment_method.dart';
import 'package:mobile/core/common/widgets/shared/phone_utils.dart';

class CheckoutPaymentSection extends StatelessWidget {
  final String? selectedPaymentMethod;
  final ValueChanged<String?> onPaymentMethodChanged;
  final List<PaymentMethod> paymentMethods;
  final TextEditingController phoneController;
  final Function(String) onPhoneChanged;

  const CheckoutPaymentSection({
    super.key,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.paymentMethods,
    required this.phoneController,
    required this.onPhoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSectionCard(
      icon: Iconsax.wallet_2,
      iconColor: Colors.purple,
      title: 'Habka Lacag Bixinta',
      children: [
        const SizedBox(height: 12),
        ...paymentMethods.map((method) {
          final isSelected = selectedPaymentMethod == method.id;
          final phone = PhoneUtils.cleanPhoneNumber(phoneController.text);
          final isInternational =
              !PhoneUtils.isSomaliNumber(phoneController.text) &&
              phoneController.text.isNotEmpty;
          final matchesProvider =
              !isInternational && phone.startsWith(method.prefix);

          return GestureDetector(
            onTap: () {
              final currentPhone = phoneController.text;
              final isCurrentInternational =
                  !PhoneUtils.isSomaliNumber(currentPhone) &&
                  currentPhone.isNotEmpty;

              // If current phone is international, clear it and set the prefix
              if (isCurrentInternational) {
                // Clear the phone and set just the prefix
                final formattedPhone = PhoneUtils.formatPhoneForDisplay(
                  method.prefix,
                );
                phoneController.text = formattedPhone;
                onPhoneChanged(formattedPhone);
              } else {
                // For Somali numbers, change the prefix
                final cleanPhone = PhoneUtils.cleanPhoneNumber(currentPhone);

                if (cleanPhone.isEmpty) {
                  // If empty, just set the prefix
                  final formattedPhone = PhoneUtils.formatPhoneForDisplay(
                    method.prefix,
                  );
                  phoneController.text = formattedPhone;
                  onPhoneChanged(formattedPhone);
                } else if (!cleanPhone.startsWith(method.prefix)) {
                  // Change the prefix
                  String newPhone = method.prefix;
                  if (cleanPhone.length > 2) {
                    newPhone = method.prefix + cleanPhone.substring(2);
                  }
                  final formattedPhone = PhoneUtils.formatPhoneForDisplay(
                    newPhone,
                  );
                  phoneController.text = formattedPhone;
                  onPhoneChanged(formattedPhone);
                }
              }

              // Change the selected payment method
              onPaymentMethodChanged(method.id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          method.color.withOpacity(0.1),
                          method.color.withOpacity(0.05),
                        ],
                      )
                    : null,
                color: isSelected ? null : const Color(0xFFF9FAFB),
                border: Border.all(
                  color: isSelected ? method.color : const Color(0xFFE5E7EB),
                  width: isSelected ? 2 : 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: method.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(method.icon, color: method.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              method.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? method.color
                                    : const Color(0xFF1F2937),
                              ),
                            ),
                            if (isSelected && matchesProvider)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: method.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '✓',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2ED573),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          method.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? method.color.withOpacity(0.7)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        if (isSelected) ...[
                          if (isInternational)
                            Text(
                              '⚠️ Lambar caalami ah lama aqbalo',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red[400],
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else if (phone.isNotEmpty && matchesProvider)
                            Text(
                              '✓ Lambar sax ah',
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFF2ED573),
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else if (phone.isNotEmpty && !matchesProvider)
                            Text(
                              '⚠️ Waa inuu ku bilaabmaa ${method.prefix}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red[400],
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else
                            Text(
                              'Fadlan geli lambarka',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: method.color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.tick_circle,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Iconsax.info_circle, color: Colors.blue[400], size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Lambarka taleefanka waa inuu ku bilaabmaa lambarka bixiyaha',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
        ),
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
}
