import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'otp_verification_screen.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  late final TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController();
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      // 🚨 CRITICAL FIX: Prevent infinite navigation loop.
      // Only trigger navigation if the state *transitions* to OtpSent.
      // If the user goes back from the OTP screen, the state is still OtpSent,
      // but because 'previous' is also OtpSent, this listener will be safely ignored.
      listenWhen: (previous, current) =>
          current is OtpSent && previous is! OtpSent,
      listener: (context, state) {
        if (state is OtpSent) {
          toastification.show(
            context: context,
            title: const Text('OTP Sent'),
            description: Text('Verification code: ${state.debugOtp}'),
            type: ToastificationType.success,
            autoCloseDuration: const Duration(seconds: 8),
            style: ToastificationStyle.fillColored,
            alignment: Alignment.topCenter,
          );

          final rawPhone = phoneController.text.trim().replaceAll(
            RegExp(r'\D'),
            '',
          );
          final normalizedPhone = '+252$rawPhone';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OtpVerificationScreen(phoneNumber: normalizedPhone),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // App Logo - More compact and elegant
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2ED573), Color(0xFF26C468)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2ED573).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.phone_android_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title - Cleaner typography
                const Text(
                  'Welcome!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your phone number to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 40),

                // --- UNIFIED PHONE INPUT ---
                // Combined into a single beautiful container instead of two separate boxes
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Country Code
                      Container(
                        width: 80,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: const Text(
                          '+252',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2ED573),
                          ),
                        ),
                      ),
                      // Input Field
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 9,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111111),
                          ),
                          decoration: InputDecoration(
                            hintText: '61 XXXXXXX',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.normal,
                            ),
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Send OTP Button
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              final rawPhone = phoneController.text.trim();

                              if (!rawPhone.startsWith('61') ||
                                  rawPhone.length != 9) {
                                toastification.show(
                                  context: context,
                                  title: const Text('Invalid Number'),
                                  description: const Text(
                                    'Please enter a valid 9-digit number starting with 61',
                                  ),
                                  type: ToastificationType.warning,
                                  autoCloseDuration: const Duration(seconds: 3),
                                );
                                return;
                              }

                              context.read<AuthBloc>().add(
                                SendOtpEvent(rawPhone),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ED573),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Send OTP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
