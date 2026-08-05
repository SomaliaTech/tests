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

  // In checkout_pay_button.dart

  bool get _canPay {
    final phone = phoneController.text;
    final cleanPhone = PhoneUtils.cleanPhoneNumber(phone);

    debugPrint('💵 [PayButton] Checking if can pay...');
    debugPrint('💵 [PayButton] Phone: "$phone"');
    debugPrint('💵 [PayButton] Clean phone: "$cleanPhone"');
    debugPrint('💵 [PayButton] Phone length: ${cleanPhone.length}');
    debugPrint('💵 [PayButton] Selected method: $selectedPaymentMethod');

    if (phone.isEmpty) {
      debugPrint('💵 [PayButton] ❌ Phone is empty');
      return false;
    }

    if (cleanPhone.length < 7) {
      debugPrint(
        '💵 [PayButton] ❌ Phone has less than 7 digits (${cleanPhone.length})',
      );
      return false;
    }

    if (selectedPaymentMethod == null) {
      debugPrint('💵 [PayButton] ❌ No payment method selected');
      return false;
    }

    try {
      final method = paymentMethods.firstWhere(
        (m) => m.id == selectedPaymentMethod,
      );
      final matches = PhoneUtils.matchesProvider(phone, method.prefix);
      debugPrint('💵 [PayButton] Matches provider ${method.prefix}: $matches');
      return matches;
    } catch (e) {
      debugPrint('💵 [PayButton] ❌ Error finding provider: $e');
      return false;
    }
  }

  String get _buttonText {
    final phone = phoneController.text;
    final cleanPhone = PhoneUtils.cleanPhoneNumber(phone);

    if (isProcessing) {
      return 'Fadlan Sug...'; // Please wait...
    }

    if (phone.isEmpty) {
      return 'Geli Lambarka Taleefanka'; // Enter Phone Number
    }

    if (cleanPhone.length < 7) {
      return 'Lambar Yar (Ugu yaraan 7)'; // Number too short (minimum 7)
    }

    if (!_canPay) {
      return 'Lambar aan sax ahayn'; // Invalid Phone Number
    }

    return 'Bixi \$${totalAmount.toStringAsFixed(2)}'; // Pay
  }

  Color get _buttonColor {
    if (_canPay) {
      return const Color(0xFF2ED573);
    }
    return const Color(0xFF9CA3AF);
  }

  @override
  Widget build(BuildContext context) {
    final canPay = _canPay;
    final buttonText = _buttonText;

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
        child: SizedBox(
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
                            canPay ? Iconsax.security_card : Iconsax.warning_2,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            buttonText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
