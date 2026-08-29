// lib/features/product/presentation/widgets/checkout/checkout_pay_button.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/common/widgets/shared/payment_method.dart';
import 'package:mobile/core/common/widgets/shared/phone_utils.dart';

class CheckoutPayButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isProcessing;
  final double totalAmount;
  final TextEditingController phoneController;
  final String? selectedPaymentMethod;
  final List<PaymentMethod> paymentMethods;

  const CheckoutPayButton({
    super.key,
    required this.onPressed,
    required this.isProcessing,
    required this.totalAmount,
    required this.phoneController,
    required this.selectedPaymentMethod,
    required this.paymentMethods,
  });

  bool _canPay(String phone) {
    final cleanPhone = PhoneUtils.cleanPhoneNumber(phone);
    final isInternational =
        !PhoneUtils.isSomaliNumber(phone) && phone.isNotEmpty;

    if (phone.isEmpty) {
      return false;
    }

    // For international numbers, payment is NOT supported
    if (isInternational) {
      return false;
    }

    // For Somali numbers, check length and provider
    if (cleanPhone.length < 7) {
      return false;
    }

    if (selectedPaymentMethod == null) {
      return false;
    }

    try {
      final method = paymentMethods.firstWhere(
        (m) => m.id == selectedPaymentMethod,
      );
      return PhoneUtils.matchesProvider(phone, method.prefix);
    } catch (e) {
      return false;
    }
  }

  String _getButtonText(String phone) {
    final cleanPhone = PhoneUtils.cleanPhoneNumber(phone);
    final isInternational =
        !PhoneUtils.isSomaliNumber(phone) && phone.isNotEmpty;

    if (isProcessing) {
      return 'Fadlan Sug...';
    }

    if (phone.isEmpty) {
      return 'Geli Lambarka Taleefanka';
    }

    if (isInternational) {
      return 'Lambar Caalami ah lama aqbalo';
    }

    if (cleanPhone.length < 7) {
      return 'Lambar Yar (Ugu yaraan 7)';
    }

    if (!_canPay(phone)) {
      return 'Lambar aan sax ahayn';
    }

    return 'Pay \$${totalAmount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: phoneController,
          builder: (context, value, child) {
            final phone = value.text;
            final canPay = _canPay(phone);
            final buttonText = _getButtonText(phone);

            return SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (canPay && !isProcessing) ? onPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: canPay
                      ? const Color(0xFF2ED573).withOpacity(0.4)
                      : Colors.transparent,
                  elevation: canPay ? 8 : 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: canPay
                        ? const LinearGradient(
                            colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF9CA3AF), Color(0xFFD1D5DB)],
                          ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: isProcessing
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                canPay
                                    ? Iconsax.security_card
                                    : Iconsax.warning_2,
                                size: 20,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  buttonText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
