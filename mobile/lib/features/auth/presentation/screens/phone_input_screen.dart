// lib/features/auth/presentation/screens/phone_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:toastification/toastification.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'otp_verification_screen.dart';
import 'welcome_screen.dart'; // ✅ Import WelcomeScreen

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  late final TextEditingController _phoneController;
  final FocusNode _phoneFocusNode = FocusNode();

  final List<ProviderInfo> _providers = const [
    ProviderInfo(
      prefix: '61',
      name: 'Hormuud',
      color: Color(0xFF2ED573),
      icon: Iconsax.mobile,
    ),
    ProviderInfo(
      prefix: '68',
      name: 'Somnet',
      color: Color(0xFF3B82F6),
      icon: Iconsax.wifi,
    ),
    ProviderInfo(
      prefix: '90',
      name: 'Golis',
      color: Color(0xFFF59E0B),
      icon: Iconsax.wallet,
    ),
    ProviderInfo(
      prefix: '63',
      name: 'Telisom',
      color: Color(0xFF8B5CF6),
      icon: Iconsax.money,
    ),
  ];

  String? _detectProvider(String phone) {
    if (phone.length < 2) return null;
    for (final provider in _providers) {
      if (phone.startsWith(provider.prefix)) return provider.name;
    }
    return null;
  }

  Color? _getProviderColor(String phone) {
    if (phone.length < 2) return null;
    for (final provider in _providers) {
      if (phone.startsWith(provider.prefix)) return provider.color;
    }
    return null;
  }

  String _formatPhoneForApi(String phone) {
    String cleaned = phone.trim().replaceAll(RegExp(r'\s+'), '');
    if (cleaned.startsWith('+252')) return cleaned;
    if (cleaned.startsWith('252')) return '+$cleaned';
    if (cleaned.startsWith('0')) return '+252${cleaned.substring(1)}';
    return '+252$cleaned';
  }

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _phoneFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _sendOtp() {
    final rawPhone = _phoneController.text.trim();
    final isValid = rawPhone.length == 9 && _detectProvider(rawPhone) != null;

    if (!isValid) {
      HapticFeedback.heavyImpact();
      toastification.show(
        context: context,
        title: const Text('Lambar aan sax ahayn'),
        description: const Text(
          'Fadlan geli lambar taleefan oo Somali ah oo 9 xaraf ah.\nLa taageeray: 61 (Hormuud), 63 (Telisom), 68 (Somnet), 90 (Golis)',
        ),
        type: ToastificationType.warning,
        autoCloseDuration: const Duration(seconds: 4),
        alignment: Alignment.topCenter,
      );
      return;
    }

    HapticFeedback.lightImpact();
    context.read<AuthBloc>().add(SendOtpEvent(rawPhone));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          return;
        }

        if (state is OtpSent) {
          HapticFeedback.mediumImpact();
          toastification.show(
            context: context,
            title: const Text('✅ OTP Sent'),
            description: const Text(
              'Check your phone for the verification code',
            ),
            type: ToastificationType.success,
            autoCloseDuration: const Duration(seconds: 3),
            alignment: Alignment.topCenter,
          );

          final rawPhone = _phoneController.text.trim().replaceAll(
            RegExp(r'\D'),
            '',
          );
          final formattedPhone = _formatPhoneForApi(rawPhone);

          Future.microtask(() {
            if (mounted) {
              // Clear the stack so back button never returns to auth screens
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) =>
                      OtpVerificationScreen(phoneNumber: formattedPhone),
                ),
                (route) => false,
              );
            }
          });
        } else if (state is Authenticated) {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (state is AuthError) {
          HapticFeedback.heavyImpact();
          toastification.show(
            context: context,
            title: const Text('Error'),
            description: Text(state.message),
            type: ToastificationType.error,
            autoCloseDuration: const Duration(seconds: 3),
            alignment: Alignment.topCenter,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left, color: Color(0xFF1F2937)),
            onPressed: () {
              // ✅ Check if there's something to pop to
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                // ✅ If nothing to pop to, go to WelcomeScreen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                );
              }
            },
          ),
          title: const Text(
            'Phone Verification',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                // Icon
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2ED573).withOpacity(0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Iconsax.call_calling,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Enter your phone number',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'We will send you a verification code',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 36),
                _buildPhoneInput(),
                const SizedBox(height: 12),
                _buildProviderDetection(),
                const SizedBox(height: 28),
                _buildSendButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    final phone = _phoneController.text;
    final providerColor = _getProviderColor(phone);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: providerColor ?? const Color(0xFFE5E7EB),
          width: providerColor != null ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                providerColor?.withOpacity(0.2) ??
                Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🇸🇴', style: TextStyle(fontSize: 14)),
                SizedBox(width: 8),
                Text(
                  '+252',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 30, color: const Color(0xFFE5E7EB)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              maxLength: 9,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: providerColor ?? const Color(0xFF1F2937),
                letterSpacing: 1.2,
              ),
              decoration: const InputDecoration(
                hintText: '61 XXX XXXX',
                hintStyle: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                ),
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderDetection() {
    final phone = _phoneController.text;
    final detectedProvider = _detectProvider(phone);
    final providerColor = _getProviderColor(phone);

    if (phone.isEmpty) {
      return Row(
        children: [
          Icon(Iconsax.info_circle, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Geli lambarka taleefanka si loo ogaado shirkaddaada',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
        ],
      );
    }

    if (detectedProvider != null && phone.length >= 2) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: providerColor?.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _providers.firstWhere((p) => p.name == detectedProvider).icon,
              size: 14,
              color: providerColor,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '📱 $detectedProvider detected',
              style: TextStyle(
                fontSize: 12,
                color: providerColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (phone.length < 9)
            Text(
              '${phone.length}/9',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
        ],
      );
    }

    return Row(
      children: [
        Icon(Iconsax.warning_2, size: 14, color: Colors.orange.shade400),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Fadlan geli lambar taleefan oo Somali ah oo sax ah',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final phone = _phoneController.text.trim();
        final isValid = phone.length == 9 && _detectProvider(phone) != null;

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (isLoading || !isValid) ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: isValid ? 8 : 0,
              shadowColor: const Color(0xFF2ED573).withOpacity(0.4),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: isValid
                    ? const LinearGradient(
                        colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF9CA3AF), Color(0xFFD1D5DB)],
                      ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isValid ? 'Send OTP' : 'Enter Valid Number',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (isValid) ...[
                            const SizedBox(width: 8),
                            const Icon(Iconsax.arrow_right_2, size: 20),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProviderInfo {
  final String prefix;
  final String name;
  final Color color;
  final IconData icon;
  const ProviderInfo({
    required this.prefix,
    required this.name,
    required this.color,
    required this.icon,
  });
}
