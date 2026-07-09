import 'package:flutter/material.dart';
import 'package:mobile/core/services/navigation_service.dart';
import 'package:mobile/features/auth/presentation/screens/phone_input_screen.dart';

class SessionHandler {
  static void navigateToLogin() {
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const PhoneInputScreen(), // ✅ Direct import
        ),
        (route) => false,
      );
    }
  }
}
