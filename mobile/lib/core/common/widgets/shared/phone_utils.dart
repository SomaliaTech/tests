// lib/features/product/presentation/utils/phone_utils.dart
import 'package:mobile/core/common/widgets/shared/payment_method.dart';
import 'package:mobile/features/notifications/data/repositories/notifications_repository_impl.dart';

class PhoneUtils {
  // Clean phone number: remove +252 if present, spaces, special chars
  static String cleanPhoneNumber(String phone) {
    debugPrint('📱 [PhoneUtils] cleanPhoneNumber input: "$phone"');

    if (phone.isEmpty) {
      debugPrint('📱 [PhoneUtils] Phone is empty, returning empty');
      return '';
    }

    String cleaned = phone.trim();

    // Remove +252 if present at start (database already has it)
    if (cleaned.startsWith('+252')) {
      cleaned = cleaned.substring(4);
      debugPrint('📱 [PhoneUtils] Removed +252 prefix: "$cleaned"');
    }
    // Remove 252 if present at start
    if (cleaned.startsWith('252')) {
      cleaned = cleaned.substring(3);
      debugPrint('📱 [PhoneUtils] Removed 252 prefix: "$cleaned"');
    }
    // Remove all non-digit characters
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    debugPrint('📱 [PhoneUtils] Final cleaned: "$cleaned"');
    return cleaned;
  }

  // Format phone for display: XX XXXXXX (without +252 prefix)
  static String formatPhoneForDisplay(String phone) {
    debugPrint('📱 [PhoneUtils] formatPhoneForDisplay input: "$phone"');

    if (phone.isEmpty) {
      debugPrint('📱 [PhoneUtils] Phone is empty, returning empty');
      return '';
    }

    final digits = cleanPhoneNumber(phone);
    if (digits.isEmpty) {
      debugPrint('📱 [PhoneUtils] No digits after cleaning, returning empty');
      return '';
    }

    // Return just the digits formatted with space for better UX
    String formatted = '';
    if (digits.length >= 2) {
      formatted += '${digits.substring(0, 2)} ';
      if (digits.length > 2) {
        formatted += digits.substring(2);
      }
    } else {
      formatted += digits;
    }

    debugPrint('📱 [PhoneUtils] Formatted: "$formatted"');
    return formatted;
  }

  // Get display phone for UI (handles database format)
  static String getDisplayPhone(String phone) {
    debugPrint('📱 [PhoneUtils] getDisplayPhone input: "$phone"');
    if (phone.isEmpty) {
      debugPrint('📱 [PhoneUtils] Phone is empty, returning empty');
      return '';
    }
    final result = formatPhoneForDisplay(phone);
    debugPrint('📱 [PhoneUtils] getDisplayPhone result: "$result"');
    return result;
  }

  // Check if phone matches provider prefix
  static bool matchesProvider(String phone, String prefix) {
    final digits = cleanPhoneNumber(phone);
    debugPrint(
      '📱 [PhoneUtils] matchesProvider - phone: "$phone", prefix: "$prefix", cleaned: "$digits"',
    );
    if (digits.length < 2) {
      debugPrint('📱 [PhoneUtils] Phone too short, returning false');
      return false;
    }
    final result = digits.startsWith(prefix);
    debugPrint('📱 [PhoneUtils] matchesProvider result: $result');
    return result;
  }

  // Detect provider from phone number
  static String? detectProvider(String phone, List<PaymentMethod> methods) {
    final digits = cleanPhoneNumber(phone);
    debugPrint(
      '📱 [PhoneUtils] detectProvider - phone: "$phone", cleaned: "$digits"',
    );

    if (digits.length < 2) {
      debugPrint('📱 [PhoneUtils] Phone too short, returning null');
      return null;
    }

    for (final method in methods) {
      if (digits.startsWith(method.prefix)) {
        debugPrint(
          '📱 [PhoneUtils] Detected provider: ${method.id} (${method.prefix})',
        );
        return method.id;
      }
    }
    debugPrint('📱 [PhoneUtils] No provider detected');
    return null;
  }

  // Format phone with a specific prefix
  static String formatPhoneWithPrefix(String phone, String prefix) {
    debugPrint(
      '📱 [PhoneUtils] formatPhoneWithPrefix - phone: "$phone", prefix: "$prefix"',
    );

    final digits = cleanPhoneNumber(phone);
    if (digits.isEmpty) {
      debugPrint('📱 [PhoneUtils] No digits, returning just prefix: "$prefix"');
      return prefix;
    }

    String newDigits = digits;
    if (!newDigits.startsWith(prefix)) {
      if (newDigits.length >= 2) {
        newDigits = prefix + newDigits.substring(2);
      } else {
        newDigits = prefix + newDigits;
      }
      debugPrint('📱 [PhoneUtils] Changed digits to: "$newDigits"');
    }

    final result = formatPhoneForDisplay(newDigits);
    debugPrint('📱 [PhoneUtils] formatPhoneWithPrefix result: "$result"');
    return result;
  }

  // Get formatted phone for API: +252XXXXXXXXXX
  static String formatPhoneForApi(String phone) {
    final digits = cleanPhoneNumber(phone);
    if (digits.isEmpty) return '';
    final result = '+252$digits';
    debugPrint('📱 [PhoneUtils] formatPhoneForApi: "$result"');
    return result;
  }
}
