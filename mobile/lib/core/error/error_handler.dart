// lib/core/utils/error_handler.dart
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:mobile/core/services/server_status_service.dart';

class ErrorHandler {
  /// Parse backend error and show user-friendly message
  static void showError(
    BuildContext context,
    dynamic error, {
    bool showToast = true,
  }) {
    final message = parseError(error);

    // ✅ Don't show toast if server is down (avoids spam)
    if (!showToast || ServerStatusService().isServerDown) {
      // Use Flutter's built-in debugPrint
      debugPrint('🔇 Suppressed toast (server down): $message');
      return;
    }

    if (context.mounted) {
      toastification.show(
        context: context,
        title: const Text('Error'),
        description: Text(message),
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        autoCloseDuration: const Duration(seconds: 4),
      );
    }
  }

  /// Parse raw error into user-friendly message
  static String parseError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    // Server down / Connection refused
    if (errorStr.contains('connection refused') ||
        errorStr.contains('connection failed') ||
        errorStr.contains('network is unreachable') ||
        errorStr.contains('server is not running') ||
        errorStr.contains('503') ||
        errorStr.contains('service unavailable')) {
      ServerStatusService().markServerDown();
      return 'Server is currently unavailable. Please try again later.';
    }

    // Network errors
    if (errorStr.contains('socketexception') ||
        errorStr.contains('no internet')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return 'Request timed out. Please try again.';
    }

    // Auth errors
    if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
      return 'Your session has expired. Please login again.';
    }
    if (errorStr.contains('403') || errorStr.contains('forbidden')) {
      return 'You do not have permission to perform this action.';
    }
    if (errorStr.contains('invalid otp')) {
      return 'The verification code you entered is incorrect.';
    }
    if (errorStr.contains('otp expired')) {
      return 'The verification code has expired. Please request a new one.';
    }

    // Validation errors
    if (errorStr.contains('email already')) {
      return 'This email is already registered.';
    }
    if (errorStr.contains('phone already')) {
      return 'This phone number is already registered.';
    }
    if (errorStr.contains('required')) {
      return 'Please fill in all required fields.';
    }

    // Stock/Order errors
    if (errorStr.contains('insufficient stock')) {
      return 'Sorry, this item is out of stock.';
    }

    // Server errors
    if (errorStr.contains('500') || errorStr.contains('internal server')) {
      return 'Something went wrong. Please try again later.';
    }
    if (errorStr.contains('404') || errorStr.contains('not found')) {
      return 'The requested item was not found.';
    }

    return _cleanErrorMessage(error.toString());
  }

  static String _cleanErrorMessage(String rawError) {
    String cleaned = rawError
        .replaceAll('ServerException: ', '')
        .replaceAll('Exception: ', '')
        .replaceAll('Error: ', '')
        .replaceAll('Failed: ', '')
        .replaceAll('Network error: ', '')
        .replaceAll('SocketException: ', '')
        .replaceAll('HttpException: ', '')
        .replaceAll('ClientException: ', '')
        .replaceAll('ClientException with ', '');

    if (cleaned.isNotEmpty) {
      cleaned = '${cleaned[0].toUpperCase()}${cleaned.substring(1)}';
    }
    if (cleaned.isEmpty) {
      cleaned = 'An unexpected error occurred. Please try again.';
    }
    return cleaned;
  }
}
