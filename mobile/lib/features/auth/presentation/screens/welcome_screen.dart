// lib/features/auth/presentation/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:toastification/toastification.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'phone_input_screen.dart';
import 'complete_profile_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _loadingProvider; // 'google' | 'facebook'

  Future<void> _handleGoogleSignIn() async {
    setState(() => _loadingProvider = 'google');
    context.read<AuthBloc>().add(const GoogleSignInEvent());
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() => _loadingProvider = 'facebook');
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
        loginBehavior: LoginBehavior.webOnly,
      );

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken!.tokenString;
        debugPrint('📘 FB token: ${accessToken.substring(0, 20)}...');
        if (mounted) {
          context.read<AuthBloc>().add(FacebookSignInEvent(accessToken));
        }
      } else {
        if (mounted) {
          setState(() => _loadingProvider = null);
          toastification.show(
            context: context,
            title: const Text('Facebook login cancelled'),
            type: ToastificationType.warning,
            autoCloseDuration: const Duration(seconds: 2),
            alignment: Alignment.topCenter,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ FB error: $e');
      if (mounted) {
        setState(() => _loadingProvider = null);
        toastification.show(
          context: context,
          title: const Text('Facebook login failed'),
          description: Text(e.toString()),
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 3),
          alignment: Alignment.topCenter,
        );
      }
    }
  }

  void _goToPhoneScreen() {
    // ✅ Use push so WelcomeScreen stays in the stack
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PhoneInputScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          return; // buttons already show their own spinners
        } else if (state is Authenticated) {
          HapticFeedback.mediumImpact();
          toastification.show(
            context: context,
            title: const Text('✅ Welcome!'),
            description: Text('Signed in as ${state.user.name ?? 'User'}'),
            type: ToastificationType.success,
            autoCloseDuration: const Duration(seconds: 2),
            alignment: Alignment.topCenter,
          );
          // ✅ Clear entire stack and go to home
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/home', (route) => false);
        } else if (state is OtpVerified) {
          HapticFeedback.mediumImpact();
          if (state.user.hasProfile) {
            // ✅ Clear entire stack and go to home
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (route) => false);
          } else {
            // ✅ Replace current screen with CompleteProfileScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CompleteProfileScreen(
                  token: state.token,
                  user: state.user,
                  isGoogleSignIn: state.isGoogleSignIn,
                ),
              ),
            );
          }
        } else if (state is ProfileCompleted) {
          // ✅ Clear entire stack and go to home
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/home', (route) => false);
        } else if (state is AuthError) {
          setState(() => _loadingProvider = null);
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
        backgroundColor: const Color(0xFF2ED573),
        body: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Brand logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Iconsax.shopping_bag,
                              color: Color(0xFF2ED573),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'FARXADA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // ✅ SOMALI LANGUAGE ADVERTISEMENT
                      Text(
                        'Ku Soo Dhawoow Farxada',
                        style: TextStyle(
                          color: Colors.grey[200],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Badeecado Caalami Ah\nIlaalin & Badbaado Dhab Ah',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Kaalay oo ku raaxeysto wax iibsiga\nsi ammaan ah oo kalsooni leh',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // BIG IMAGE
                      Container(
                        width: double.infinity,
                        height: 260,
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Image.asset(
                          "assets/images/logo_welcome.png",
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.15),
                              ),
                              child: const Icon(
                                Iconsax.shopping_bag,
                                color: Colors.white,
                                size: 100,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==========================================
              // BOTTOM CARD (buttons)
              // ==========================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Google
                    _buildAuthButton(
                      isLoading: _loadingProvider == 'google',
                      label: 'Continue with Google',
                      icon: Image.network(
                        'https://www.google.com/favicon.ico',
                        height: 22,
                        width: 22,
                        errorBuilder: (_, __, ___) => const Icon(
                          Iconsax.activity,
                          color: Color(0xFFEA4335),
                          size: 22,
                        ),
                      ),
                      borderColor: const Color(0xFFDADCE0),
                      textColor: const Color(0xFF3C4043),
                      onTap: _handleGoogleSignIn,
                    ),
                    const SizedBox(height: 12),
                    // Facebook
                    _buildAuthButton(
                      isLoading: _loadingProvider == 'facebook',
                      label: 'Continue with Facebook',
                      icon: const Icon(
                        Icons.facebook,
                        color: Color(0xFF1877F2),
                        size: 24,
                      ),
                      borderColor: const Color(0xFFDADCE0),
                      textColor: const Color(0xFF3C4043),
                      onTap: _handleFacebookSignIn,
                    ),
                    const SizedBox(height: 16),
                    // OR divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Phone (primary)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _loadingProvider != null
                            ? null
                            : _goToPhoneScreen,
                        icon: const Icon(Iconsax.mobile, size: 20),
                        label: const Text(
                          'Continue with Phone',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ED573),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Markaad sii waddo, waxaad ogolaanaysaa Shuruudaha Adeegga\niyo Xeerka Qarsoodiga',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton({
    required String label,
    required Widget icon,
    required Color borderColor,
    required Color textColor,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: (_loadingProvider != null) ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
