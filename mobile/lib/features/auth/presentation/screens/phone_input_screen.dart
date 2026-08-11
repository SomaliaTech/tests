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
import 'complete_profile_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // ✅ Log EVERY state change
        debugPrint('🔔🔔🔔 LISTENER TRIGGERED: ${state.runtimeType} 🔔🔔🔔');

        if (state is AuthLoading) {
          debugPrint('⏳ AuthLoading - no navigation');
          return;
        }

        if (state is AuthInitial) {
          debugPrint('🔹 AuthInitial - no navigation');
          return;
        }

        if (state is AuthChecking) {
          debugPrint('🔹 AuthChecking - no navigation');
          return;
        }

        if (state is OtpSent) {
          debugPrint('✅ OtpSent - navigating to OTP screen');
          HapticFeedback.mediumImpact();
          toastification.show(
            context: context,
            title: const Text('✅ OTP Sent'),
            description: Text('Verification code: ${state.debugOtp}'),
            type: ToastificationType.success,
            autoCloseDuration: const Duration(seconds: 8),
            style: ToastificationStyle.fillColored,
            alignment: Alignment.topCenter,
          );

          final rawPhone = _phoneController.text.trim().replaceAll(
            RegExp(r'\D'),
            '',
          );
          final formattedPhone = _formatPhoneForApi(rawPhone);

          Future.microtask(() {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      OtpVerificationScreen(phoneNumber: formattedPhone),
                ),
              );
            }
          });
        } else if (state is Authenticated) {
          debugPrint('✅ Authenticated - navigating to HOME');
          HapticFeedback.mediumImpact();
          toastification.show(
            context: context,
            title: const Text('✅ Welcome!'),
            description: Text('Signed in as ${state.user.name ?? 'User'}'),
            type: ToastificationType.success,
            autoCloseDuration: const Duration(seconds: 3),
            style: ToastificationStyle.fillColored,
            alignment: Alignment.topCenter,
          );

          Future.microtask(() {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          });
        } else if (state is OtpVerified) {
          debugPrint('✅✅✅ OtpVerified - NAVIGATING TO COMPLETE PROFILE ✅✅✅');
          debugPrint('  Token: ${state.token}');
          debugPrint('  User name: ${state.user.name}');
          debugPrint('  User email: ${state.user.email}');
          debugPrint('  User phone: ${state.user.phoneNumber}');
          debugPrint('  Has profile: ${state.user.hasProfile}');
          debugPrint('  Market ID: ${state.user.marketId}');

          HapticFeedback.mediumImpact();

          final isGoogleUser =
              state.user.email != null && state.user.email!.isNotEmpty;
          debugPrint('  Is Google user: $isGoogleUser');

          Future.microtask(() {
            if (mounted) {
              debugPrint(
                '🚀🚀🚀 EXECUTING NAVIGATION TO CompleteProfileScreen 🚀🚀🚀',
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => CompleteProfileScreen(
                    token: state.token,
                    user: state.user,
                    isGoogleSignIn: isGoogleUser,
                  ),
                ),
              );
            }
          });
        } else if (state is ProfileCompleted) {
          debugPrint('✅ ProfileCompleted - navigating to HOME');
          Future.microtask(() {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          });
        } else if (state is AuthError) {
          debugPrint('❌ Auth Error: ${state.message}');
          HapticFeedback.heavyImpact();
          toastification.show(
            context: context,
            title: const Text('Error'),
            description: Text(state.message),
            type: ToastificationType.error,
            autoCloseDuration: const Duration(seconds: 3),
          );
        } else if (state is GoogleSignInSuccess) {
          debugPrint('✅ GoogleSignInSuccess - checking profile...');
          if (!state.user.hasProfile || state.user.marketId == null) {
            debugPrint('  -> Needs profile completion');
            final isGoogleUser =
                state.user.email != null && state.user.email!.isNotEmpty;
            Future.microtask(() {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompleteProfileScreen(
                      token: state.token,
                      user: state.user,
                      isGoogleSignIn: isGoogleUser,
                    ),
                  ),
                );
              }
            });
          } else {
            debugPrint('  -> Profile complete, going home');
            Future.microtask(() {
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/home');
              }
            });
          }
        } else {
          debugPrint('⚠️ UNHANDLED STATE: ${state.runtimeType}');
        }
      },

      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      _buildIcon(),
                      const SizedBox(height: 24),
                      const Text(
                        'Welcome!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter your phone number to get\nstarted with your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildPhoneInput(),
                      const SizedBox(height: 12),
                      _buildProviderDetection(),
                      const SizedBox(height: 24),
                      _buildSendButton(),
                      const SizedBox(height: 16),
                      _buildDivider(),
                      const SizedBox(height: 16),
                      _buildGoogleSignInButton(),
                      const SizedBox(height: 24),
                      _buildInfoCard(),
                      const SizedBox(height: 24),
                      Text(
                        'By continuing, you agree to our Terms of Service and Privacy Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.mobile, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Step 1 of 2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
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
      child: const Icon(Iconsax.call_calling, size: 44, color: Colors.white),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4189DD),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Center(
                    child: Text('🇸🇴', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '+252',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Iconsax.arrow_down_1,
                  size: 14,
                  color: Color(0xFF9CA3AF),
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
              decoration: InputDecoration(
                hintText: '61 XXX XXXX',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                ),
                counterText: '',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Icon(Iconsax.info_circle, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Enter a phone number to detect your provider',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      );
    }

    if (detectedProvider != null && phone.length >= 2) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
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
            if (phone.length >= 2 && phone.length < 9)
              Text(
                '${phone.length}/9',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(Iconsax.warning_2, size: 14, color: Colors.orange.shade400),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Please enter a valid Somali phone number',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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
            onPressed: isLoading || !isValid
                ? null
                : () {
                    final rawPhone = _phoneController.text.trim();
                    if (!isValid) {
                      HapticFeedback.heavyImpact();
                      toastification.show(
                        context: context,
                        title: const Text('Invalid Number'),
                        description: const Text(
                          'Please enter a valid 9-digit Somali phone number.\nSupported: 61 (EVC), 63 (Telisom), 68 (Somnet), 90 (Golis)',
                        ),
                        type: ToastificationType.warning,
                        autoCloseDuration: const Duration(seconds: 4),
                      );
                      return;
                    }
                    HapticFeedback.lightImpact();
                    context.read<AuthBloc>().add(SendOtpEvent(rawPhone));
                  },
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

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'OR',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: isLoading
                ? null
                : () {
                    debugPrint('🔵 Google Sign-In button pressed');
                    HapticFeedback.lightImpact();
                    context.read<AuthBloc>().add(const GoogleSignInEvent());
                  },
            icon: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.grey,
                    ),
                  )
                : Image.network(
                    'https://www.google.com/favicon.ico',
                    height: 24,
                    width: 24,
                  ),
            label: Text(
              isLoading ? 'Signing in...' : 'Continue with Google',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3C4043),
              side: const BorderSide(color: Color(0xFFDADCE0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2ED573).withOpacity(0.08),
            const Color(0xFF1ABC9C).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2ED573).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2ED573).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Iconsax.shield_tick,
              color: Color(0xFF2ED573),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Sign In',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Use your phone number or Google account',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
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
