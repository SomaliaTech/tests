// lib/features/product/presentation/widgets/checkout/checkout_address_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/common/widgets/shared/payment_method.dart';
import 'package:mobile/core/common/widgets/shared/phone_utils.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_state.dart';

// ✅ Make the state public by removing the underscore
class CheckoutAddressSection extends StatefulWidget {
  final String? selectedLabel;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final String? selectedPaymentMethod;
  final List<PaymentMethod> paymentMethods;
  final Function(String) onPhoneChanged;

  const CheckoutAddressSection({
    super.key,
    required this.selectedLabel,
    required this.addressController,
    required this.phoneController,
    required this.selectedPaymentMethod,
    required this.paymentMethods,
    required this.onPhoneChanged,
  });

  @override
  State<CheckoutAddressSection> createState() => CheckoutAddressSectionState();
}

// ✅ Make the state public by removing the underscore
class CheckoutAddressSectionState extends State<CheckoutAddressSection> {
  bool _isInitialized = false;
  String? _phoneError;

  // ✅ Public method to show error from parent
  void showError(String error) {
    setState(() {
      _phoneError = error;
    });
  }

  // ✅ Public method to clear error
  void clearError() {
    setState(() {
      _phoneError = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _tryFillPhoneNumber();
  }

  void _tryFillPhoneNumber() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final authState = context.read<AuthBloc>().state;
        final phone = _extractPhoneNumber(authState);
        if (phone.isNotEmpty && widget.phoneController.text.isEmpty) {
          final displayPhone = PhoneUtils.getDisplayPhone(phone);
          widget.phoneController.text = displayPhone;
          widget.onPhoneChanged(displayPhone);
          _isInitialized = true;

          final detectedProvider = PhoneUtils.detectProvider(
            phone,
            widget.paymentMethods,
          );
          if (detectedProvider != null) {
            widget.onPhoneChanged(displayPhone);
          }
        }
      } catch (e) {
        debugPrint('Could not read auth state: $e');
      }
    });
  }

  void _formatPhoneInput(String value) {
    // Remove all non-digit characters
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Remove 252 if present (from pasting)
    if (digits.startsWith('252')) {
      digits = digits.substring(3);
    }

    // Remove +252 if present (from pasting)
    if (digits.startsWith('00252')) {
      digits = digits.substring(5);
    }

    // If digits is empty, clear the input
    if (digits.isEmpty) {
      widget.phoneController.text = '';
      setState(() {
        _phoneError = null;
      });
      return;
    }

    // If digits is just the prefix (2 digits), show without space
    if (digits.length == 2) {
      widget.phoneController.value = widget.phoneController.value.copyWith(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
      final detectedProvider = PhoneUtils.detectProvider(
        digits,
        widget.paymentMethods,
      );
      if (detectedProvider != null &&
          detectedProvider != widget.selectedPaymentMethod) {
        widget.onPhoneChanged(digits);
      }
      setState(() {
        _phoneError = null;
      });
      return;
    }

    // Limit to 10 digits max (61 + 8 digits)
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    // Format: XX XXXXXX (without +252 prefix)
    String formatted = '';
    if (digits.isNotEmpty) {
      if (digits.length >= 2) {
        formatted += '${digits.substring(0, 2)} ';
        if (digits.length > 2) {
          formatted += digits.substring(2);
        }
      } else {
        formatted += digits;
      }
    }

    // Update controller without triggering onChanged again
    widget.phoneController.value = widget.phoneController.value.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    // Auto-detect provider
    if (digits.length >= 2) {
      final detectedProvider = PhoneUtils.detectProvider(
        digits,
        widget.paymentMethods,
      );
      if (detectedProvider != null &&
          detectedProvider != widget.selectedPaymentMethod) {
        widget.onPhoneChanged(formatted);
      }
    }

    // Validate phone and show error below input
    _validatePhone(formatted);

    setState(() {});
  }

  void _validatePhone(String phone) {
    final cleanPhone = PhoneUtils.cleanPhoneNumber(phone);

    if (phone.isEmpty) {
      setState(() {
        _phoneError = null;
      });
      return;
    }

    if (cleanPhone.length < 7) {
      setState(() {
        _phoneError =
            'Lambarka taleefanka waa inuu ka kooban yahay ugu yaraan 7 lambar (waxaad haysaa ${cleanPhone.length})';
      });
      return;
    }

    // Check if matches provider
    if (_currentPaymentMethod != null) {
      final isValid = PhoneUtils.matchesProvider(
        phone,
        _currentPaymentMethod!.prefix,
      );
      if (!isValid) {
        setState(() {
          _phoneError = 'Waa inuu ku bilaabmaa ${_providerPrefixDisplay}';
        });
        return;
      }
    }

    // No errors
    setState(() {
      _phoneError = null;
    });
  }

  String _extractPhoneNumber(AuthState state) {
    if (state is Authenticated) return state.user.phoneNumber;
    if (state is OtpVerified) return state.user.phoneNumber;
    if (state is ProfileCompleted) return state.user.phoneNumber;
    return '';
  }

  PaymentMethod? get _currentPaymentMethod {
    try {
      return widget.paymentMethods.firstWhere(
        (m) => m.id == widget.selectedPaymentMethod,
      );
    } catch (e) {
      return widget.paymentMethods.first;
    }
  }

  bool get _isPhoneValid {
    final phone = widget.phoneController.text;
    final currentMethod = _currentPaymentMethod;
    if (phone.isEmpty || currentMethod == null) return false;
    return PhoneUtils.matchesProvider(phone, currentMethod.prefix);
  }

  bool get _hasMinDigits {
    final phone = widget.phoneController.text;
    final cleanPhone = PhoneUtils.cleanPhoneNumber(phone);
    return cleanPhone.length >= 7;
  }

  String get _providerPrefixDisplay {
    final currentMethod = _currentPaymentMethod;
    if (currentMethod == null) return '+252';
    return '+252${currentMethod.prefix}';
  }

  String get _phonePlaceholder {
    final currentMethod = _currentPaymentMethod;
    if (currentMethod == null) return 'Geli lambarka taleefanka';
    return '${currentMethod.prefix} XXXXXX';
  }

  String get _providerName {
    final currentMethod = _currentPaymentMethod;
    if (currentMethod == null) return '';
    return currentMethod.name;
  }

  @override
  Widget build(BuildContext context) {
    final isPhoneValid = _isPhoneValid;
    final hasMinDigits = _hasMinDigits;
    final phone = widget.phoneController.text;
    final cleanPhone = PhoneUtils.cleanPhoneNumber(phone);
    final phoneLength = cleanPhone.length;
    final hasError = _phoneError != null;

    return _buildSectionCard(
      icon: Iconsax.location,
      iconColor: const Color(0xFF2ED573),
      title: 'Delivery Address',
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.selectedLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ED573).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.selectedLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2ED573),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                widget.addressController.text.isNotEmpty
                    ? widget.addressController.text
                    : 'Cinwaan lama helin',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.addressController.text.isNotEmpty
                      ? const Color(0xFF1F2937)
                      : Colors.red,
                ),
              ),
              const SizedBox(height: 12),

              // Phone Number
              const Text(
                'Lambarka Taleefanka',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 6),

              // Phone Input Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasError
                        ? Colors.red
                        : isPhoneValid && hasMinDigits
                        ? const Color(0xFF2ED573)
                        : const Color(0xFFE5E7EB),
                    width: hasError ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Prefix with +252
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _currentPaymentMethod?.color.withOpacity(0.1) ??
                            Colors.grey.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                        border: Border(
                          right: BorderSide(
                            color: Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.call,
                            size: 16,
                            color: _currentPaymentMethod?.color ?? Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+252',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  _currentPaymentMethod?.color ??
                                  const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Phone input
                    Expanded(
                      child: TextFormField(
                        controller: widget.phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: _phonePlaceholder,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          suffixIcon: phone.isNotEmpty && phone.length > 2
                              ? Icon(
                                  hasError
                                      ? Iconsax.warning_2
                                      : isPhoneValid && hasMinDigits
                                      ? Iconsax.verify
                                      : Iconsax.warning_2,
                                  color: hasError
                                      ? Colors.red
                                      : isPhoneValid && hasMinDigits
                                      ? const Color(0xFF2ED573)
                                      : Colors.orange,
                                  size: 20,
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          if (value.isEmpty) {
                            widget.phoneController.text = '';
                            setState(() {
                              _phoneError = null;
                            });
                            return;
                          }
                          if (value
                              .replaceAll(RegExp(r'[^0-9]'), '')
                              .isNotEmpty) {
                            _formatPhoneInput(value);
                          }
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ Error message below the input
              if (hasError) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      const Icon(Iconsax.danger, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _phoneError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Character count and status (only when no error)
              if (!hasError && phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      phoneLength < 7
                          ? 'Ugu yaraan 7 lambar ayaa loo baahan yahay'
                          : isPhoneValid
                          ? '✓ Lambar sax ah'
                          : '⚠️ Waa inuu ku bilaabmaa ${_providerPrefixDisplay}',
                      style: TextStyle(
                        fontSize: 10,
                        color: phoneLength < 7
                            ? Colors.orange[600]
                            : isPhoneValid
                            ? const Color(0xFF2ED573)
                            : Colors.red[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$phoneLength/10',
                      style: TextStyle(
                        fontSize: 10,
                        color: phoneLength >= 7
                            ? const Color(0xFF2ED573)
                            : Colors.orange[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              // Provider info (only when no error)
              if (!hasError) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPhoneValid && hasMinDigits
                        ? const Color(0xFF2ED573).withOpacity(0.05)
                        : Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPhoneValid && hasMinDigits
                          ? const Color(0xFF2ED573).withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPhoneValid && hasMinDigits
                            ? Iconsax.tick_circle
                            : Iconsax.info_circle,
                        color: isPhoneValid && hasMinDigits
                            ? const Color(0xFF2ED573)
                            : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isPhoneValid && hasMinDigits
                              ? '✓ Lambar sax ah oo $_providerName ah'
                              : phone.isEmpty || phone.length < 5
                              ? 'Fadlan geli lambarka $_providerName'
                              : phoneLength < 7
                              ? '⚠️ Fadlan geli ugu yaraan 7 lambar'
                              : '⚠️ Waa inuu ku bilaabmaa ${_providerPrefixDisplay}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isPhoneValid && hasMinDigits
                                ? const Color(0xFF2ED573)
                                : Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Payment method info
        if (widget.selectedPaymentMethod != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  _currentPaymentMethod?.color.withOpacity(0.05) ??
                  Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _currentPaymentMethod?.color.withOpacity(0.2) ??
                    Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        _currentPaymentMethod?.color.withOpacity(0.15) ??
                        Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _currentPaymentMethod?.icon ?? Iconsax.mobile,
                    color: _currentPaymentMethod?.color ?? Colors.grey,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lambarka Lacag Bixinta',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _currentPaymentMethod?.color ?? Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_currentPaymentMethod?.name ?? "Payment"} waxaa loo diri doonaa: ${phone.isNotEmpty ? PhoneUtils.formatPhoneForApi(phone) : "Lambar lama gelin"}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
