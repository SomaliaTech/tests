import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ✅ Add these methods
  static void navigateToChat(String partnerId) {
    navigatorKey.currentState?.pushNamed(
      '/chat-room',
      arguments: {'partnerId': partnerId},
    );
  }

  static void navigateToOrderDetails(String orderId) {
    navigatorKey.currentState?.pushNamed(
      '/order-details',
      arguments: {'orderId': orderId},
    );
  }

  static void navigateToNotifications() {
    navigatorKey.currentState?.pushNamed('/notifications');
  }

  // ✅ Generic navigation method
  static void navigateTo(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  // ✅ Pop to root
  static void popToRoot() {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
}
