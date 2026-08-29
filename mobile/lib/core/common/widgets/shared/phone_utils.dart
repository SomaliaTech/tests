// lib/core/common/widgets/shared/phone_utils.dart
import 'package:flutter/material.dart';
import 'package:mobile/core/common/widgets/shared/payment_method.dart';

class PhoneUtils {
  // Detect if phone number is Somali or international
  static bool isSomaliNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Empty or very short numbers - treat as Somali (default)
    if (digits.length <= 2) {
      return true; // Default to Somali for short inputs
    }

    // Check for Somali prefixes
    return digits.startsWith('252') ||
        digits.startsWith('061') ||
        digits.startsWith('61') ||
        digits.startsWith('63') ||
        digits.startsWith('68') ||
        digits.startsWith('90');
  }

  // Clean phone number: extract just the local part for Somali numbers
  static String cleanPhoneNumber(String phone) {
    debugPrint('📱 [PhoneUtils] cleanPhoneNumber input: "$phone"');

    if (phone.isEmpty) {
      debugPrint('📱 [PhoneUtils] Phone is empty, returning empty');
      return '';
    }

    String cleaned = phone.trim();

    // For international numbers (not Somali), keep the full number
    if (!isSomaliNumber(cleaned)) {
      // Remove all non-digit characters except + for international
      cleaned = cleaned.replaceAll(RegExp(r'[^\d+]'), '');
      debugPrint('📱 [PhoneUtils] International number: "$cleaned"');
      return cleaned;
    }

    // For Somali numbers, extract local part
    // Remove +252 if present
    if (cleaned.startsWith('+252')) {
      cleaned = cleaned.substring(4);
    }
    // Remove 252 if present
    if (cleaned.startsWith('252')) {
      cleaned = cleaned.substring(3);
    }
    // Remove leading 0 if present (0612345678 -> 612345678)
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    // Remove all non-digit characters
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9]'), '');

    debugPrint('📱 [PhoneUtils] Somali number cleaned: "$cleaned"');
    return cleaned;
  }

  // Format phone for display
  static String formatPhoneForDisplay(String phone) {
    debugPrint('📱 [PhoneUtils] formatPhoneForDisplay input: "$phone"');

    if (phone.isEmpty) {
      return '';
    }

    // For international numbers, keep as is
    if (!isSomaliNumber(phone) && phone.length > 4) {
      debugPrint('📱 [PhoneUtils] International, keeping as: "$phone"');
      return phone;
    }

    // For Somali numbers, format as XX XXXXXX
    final digits = cleanPhoneNumber(phone);
    if (digits.isEmpty) {
      return '';
    }

    String formatted = '';
    if (digits.length >= 2) {
      formatted += '${digits.substring(0, 2)} ';
      if (digits.length > 2) {
        formatted += digits.substring(2);
      }
    } else {
      formatted += digits;
    }

    debugPrint('📱 [PhoneUtils] Somali formatted: "$formatted"');
    return formatted;
  }

  // Get display phone for UI
  static String getDisplayPhone(String phone) {
    debugPrint('📱 [PhoneUtils] getDisplayPhone input: "$phone"');
    if (phone.isEmpty) {
      return '';
    }

    // For international numbers, return as is
    if (!isSomaliNumber(phone) && phone.length > 4) {
      debugPrint('📱 [PhoneUtils] International, returning: "$phone"');
      return phone;
    }

    final result = formatPhoneForDisplay(phone);
    debugPrint('📱 [PhoneUtils] getDisplayPhone result: "$result"');
    return result;
  }

  // Check if phone matches provider prefix (only for Somali numbers)
  static bool matchesProvider(String phone, String prefix) {
    // For very short inputs (less than 3 digits), check if prefix starts with it
    final digits = cleanPhoneNumber(phone);

    debugPrint(
      '📱 [PhoneUtils] matchesProvider - phone: "$phone", prefix: "$prefix", cleaned: "$digits"',
    );

    if (digits.isEmpty) {
      return false;
    }

    // If digits are shorter than prefix, check if prefix starts with digits
    if (digits.length < prefix.length) {
      return prefix.startsWith(digits);
    }

    final result = digits.startsWith(prefix);
    debugPrint('📱 [PhoneUtils] matchesProvider result: $result');
    return result;
  }

  // Detect provider from phone number (only for Somali numbers)
  static String? detectProvider(String phone, List<PaymentMethod> methods) {
    if (!isSomaliNumber(phone)) {
      debugPrint('📱 [PhoneUtils] International number, no Somali provider');
      return null;
    }

    final digits = cleanPhoneNumber(phone);
    debugPrint(
      '📱 [PhoneUtils] detectProvider - phone: "$phone", cleaned: "$digits"',
    );

    if (digits.isEmpty) {
      return null;
    }

    for (final method in methods) {
      if (digits.startsWith(method.prefix) ||
          method.prefix.startsWith(digits)) {
        debugPrint(
          '📱 [PhoneUtils] Detected provider: ${method.id} (${method.prefix})',
        );
        return method.id;
      }
    }
    debugPrint('📱 [PhoneUtils] No provider detected');
    return null;
  }

  // Format phone for API
  static String formatPhoneForApi(String phone) {
    debugPrint('📱 [PhoneUtils] formatPhoneForApi input: "$phone"');

    // For international numbers, return as is
    if (!isSomaliNumber(phone) && phone.length > 4) {
      debugPrint('📱 [PhoneUtils] International, returning: "$phone"');
      return phone;
    }

    // For Somali numbers, add +252 prefix
    final digits = cleanPhoneNumber(phone);
    if (digits.isEmpty) return '';
    final result = '+252$digits';
    debugPrint('📱 [PhoneUtils] Somali formatPhoneForApi: "$result"');
    return result;
  }
}
