// lib/features/auth/presentation/screens/phone_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'otp_verification_screen.dart';

class PhoneInputScreen extends StatelessWidget {
  final TextEditingController phoneController = TextEditingController();

  PhoneInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is OtpSent) {
          toastification.show(
            context: context,
            title: const Text('✓ OTP Sent Successfully'),
            description: Text('Your verification code: ${state.debugOtp}'),
            type: ToastificationType.success,
            autoCloseDuration: const Duration(seconds: 5),
            style: ToastificationStyle.fillColored,
            alignment: Alignment.topCenter,
          );

          // Normalize format cleanly to pass downstream
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
        } else if (state is AuthError) {
          toastification.show(
            context: context,
            title: const Text('Error'),
            description: Text(state.message),
            type: ToastificationType.error,
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // App Logo
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2ED573).withOpacity(0.8),
                          const Color(0xFF2ED573),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2ED573).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.phone_android_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Title
                const Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enter your phone number to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 48),

                // --- CUSTOM PHONE INPUT ROW (+252 + Input) ---
                Row(
                  children: [
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '+252',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2ED573),
                        ),
                      ),
                    ),

                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 9,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          hintText: '61 XXXXXXXXX',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            borderSide: const BorderSide(
                              color: Color(0xFF2ED573),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ),
                  ],
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
                              String cleanNumber = rawPhone.replaceAll(
                                RegExp(r'\D'),
                                '',
                              );

                              if (!cleanNumber.startsWith('61') ||
                                  cleanNumber.length != 9) {
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

                              // Pre-normalize it here so backend gets '+25261...' directly
                              final formattedToSend = '+252$cleanNumber';
                              context.read<AuthBloc>().add(
                                SendOtpEvent(formattedToSend),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ED573),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
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
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 40),

                Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
