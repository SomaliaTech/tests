// lib/core/services/storage/storage_service.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';
  static const String _userProfileImageKey = 'user_profile_image';
  static const String _userMarketIdKey = 'user_market_id';
  static const String _isAdminKey = 'is_admin';
  static const String _isSuperAdminKey = 'is_super_admin';
  static const String _messageSoundKey = 'message_sound_enabled';
  static const String _permissionsKey = 'cached_permissions';
  static const String _lastActivityKey = 'last_activity_timestamp';

  final FlutterSecureStorage _secureStorage;

  // ✅ In-memory cache to prevent read delays
  String? _cachedToken;
  bool? _cachedIsSuperAdmin;
  List<String>? _cachedPermissions;
  DateTime? _lastActivity;

  StorageService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // ==========================================
  // 🔒 DEVICE SECURITY CHECKS
  // ==========================================

  /// Check if the device is secure (not rooted/jailbroken)
  static Future<bool> isDeviceSecure() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Check for root indicators
        final isRooted =
            androidInfo.isPhysicalDevice == false ||
            androidInfo.bootloader?.contains('root') == true ||
            androidInfo.fingerprint?.contains('test-keys') == true ||
            androidInfo.hardware?.contains('goldfish') == true;

        if (isRooted) {
          debugPrint('⚠️ Device appears to be rooted');
          return false;
        }
        return true;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // Check for jailbreak indicators
        final isJailbroken =
            iosInfo.isPhysicalDevice == false ||
            iosInfo.name?.contains('iPhone') == false;

        if (isJailbroken) {
          debugPrint('⚠️ Device appears to be jailbroken');
          return false;
        }
        return true;
      }

      return true;
    } catch (e) {
      // If we can't check, assume device is secure
      debugPrint('⚠️ Could not check device security: $e');
      return true;
    }
  }

  // ==========================================
  // 🔐 SESSION MANAGEMENT
  // ==========================================

  /// Update last activity timestamp
  Future<void> updateLastActivity() async {
    _lastActivity = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActivityKey, _lastActivity!.toIso8601String());
  }

  /// Get last activity timestamp
  Future<DateTime?> getLastActivity() async {
    if (_lastActivity != null) return _lastActivity;

    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastActivityKey);
    if (timestamp != null) {
      _lastActivity = DateTime.parse(timestamp);
      return _lastActivity;
    }
    return null;
  }

  /// Check if session is expired (30 minutes timeout)
  Future<bool> isSessionExpired() async {
    final lastActivity = await getLastActivity();
    if (lastActivity == null) return true;

    final difference = DateTime.now().difference(lastActivity);
    return difference.inMinutes > 30; // 30 minute timeout
  }

  // ==========================================
  // 🔑 PERMISSIONS MANAGEMENT
  // ==========================================

  Future<void> savePermissions(List<String> permissions) async {
    debugPrint('💾 Saving permissions: ${permissions.length} permissions');
    _cachedPermissions = permissions;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_permissionsKey, permissions);
    debugPrint('💾 Permissions saved successfully');
  }

  Future<List<String>> getPermissions() async {
    if (_cachedPermissions != null) {
      return _cachedPermissions!;
    }

    final prefs = await SharedPreferences.getInstance();
    final permissions = prefs.getStringList(_permissionsKey) ?? [];
    _cachedPermissions = permissions;
    return permissions;
  }

  Future<void> clearPermissions() async {
    _cachedPermissions = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_permissionsKey);
  }

  Future<bool> hasPermission(String permission) async {
    final permissions = await getPermissions();
    return permissions.contains(permission);
  }

  // ==========================================
  // 🔐 AUTH TOKEN (Stored securely)
  // ==========================================

  Future<void> saveAuthToken(String token) async {
    if (token.isEmpty) {
      debugPrint('⚠️ Attempted to save empty token, ignoring');
      return;
    }
    _cachedToken = token;
    await _secureStorage.write(key: _tokenKey, value: token);
    await updateLastActivity();
    debugPrint('✅ Auth token saved securely (length: ${token.length})');
  }

  Future<String?> getAuthToken() async {
    // Check session expiry
    if (await isSessionExpired()) {
      debugPrint('⚠️ Session expired, clearing token');
      await clearAuthData();
      return null;
    }

    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }

    final token = await _secureStorage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) {
      _cachedToken = token;
    }
    return token;
  }

  Future<void> clearAuthToken() async {
    _cachedToken = null;
    await _secureStorage.delete(key: _tokenKey);
    debugPrint('🗑️ Auth token cleared from secure storage');
  }

  // ==========================================
  // 👤 USER ID
  // ==========================================

  Future<void> saveUserId(String userId) async {
    await _secureStorage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  // ==========================================
  // 🔓 LOGIN STATUS
  // ==========================================

  Future<void> saveLoginStatus(bool isLoggedIn) async {
    await _secureStorage.write(
      key: _isLoggedInKey,
      value: isLoggedIn.toString(),
    );
    if (isLoggedIn) {
      await updateLastActivity();
    }
  }

  Future<bool> isAuthenticated() async {
    // First check if device is secure
    if (!(await isDeviceSecure())) {
      await clearAuthData();
      return false;
    }

    final token = await getAuthToken();
    final isLoggedIn = await _secureStorage.read(key: _isLoggedInKey);
    return token != null && token.isNotEmpty && isLoggedIn == 'true';
  }

  // ==========================================
  // 👑 ADMIN STATUS
  // ==========================================

  Future<void> saveIsAdmin(bool isAdmin) async {
    await _secureStorage.write(key: _isAdminKey, value: isAdmin.toString());
  }

  Future<bool> getIsAdmin() async {
    final value = await _secureStorage.read(key: _isAdminKey);
    return value == 'true';
  }

  Future<void> saveIsSuperAdmin(bool isSuperAdmin) async {
    _cachedIsSuperAdmin = isSuperAdmin;
    await _secureStorage.write(
      key: _isSuperAdminKey,
      value: isSuperAdmin.toString(),
    );
  }

  Future<bool> getIsSuperAdmin() async {
    if (_cachedIsSuperAdmin != null) {
      return _cachedIsSuperAdmin!;
    }
    final value = await _secureStorage.read(key: _isSuperAdminKey);
    final result = value == 'true';
    _cachedIsSuperAdmin = result;
    return result;
  }

  // ==========================================
  // 👤 PROFILE INFORMATION
  // ==========================================

  Future<void> saveUserName(String name) async {
    await _secureStorage.write(key: _userNameKey, value: name);
  }

  Future<String?> getUserName() async {
    return await _secureStorage.read(key: _userNameKey);
  }

  Future<void> saveUserEmail(String email) async {
    await _secureStorage.write(key: _userEmailKey, value: email);
  }

  Future<String?> getUserEmail() async {
    return await _secureStorage.read(key: _userEmailKey);
  }

  Future<void> saveUserPhone(String phone) async {
    await _secureStorage.write(key: _userPhoneKey, value: phone);
  }

  Future<String?> getUserPhone() async {
    return await _secureStorage.read(key: _userPhoneKey);
  }

  Future<void> saveUserProfileImage(String imageUrl) async {
    await _secureStorage.write(key: _userProfileImageKey, value: imageUrl);
  }

  Future<String?> getUserProfileImage() async {
    return await _secureStorage.read(key: _userProfileImageKey);
  }

  Future<void> saveUserMarketId(String marketId) async {
    await _secureStorage.write(key: _userMarketIdKey, value: marketId);
  }

  Future<String?> getUserMarketId() async {
    return await _secureStorage.read(key: _userMarketIdKey);
  }

  // ==========================================
  // 🔇 CHAT MUTE SETTINGS (SharedPreferences - non-sensitive)
  // ==========================================

  Future<void> setChatMuted(String chatId, bool isMuted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('chat_muted_$chatId', isMuted);
  }

  Future<bool> isChatMuted(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('chat_muted_$chatId') ?? false;
  }

  // ==========================================
  // 🔊 SOUND SETTINGS (SharedPreferences - non-sensitive)
  // ==========================================

  Future<bool> getMessageSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_messageSoundKey) ?? true;
  }

  Future<void> setMessageSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_messageSoundKey, enabled);
  }

  // ==========================================
  // 🗑️ CLEAR ALL DATA (Logout)
  // ==========================================

  Future<void> clearAuthData() async {
    debugPrint('🗑️ Clearing all auth data from secure storage...');

    // Clear cache
    _cachedToken = null;
    _cachedIsSuperAdmin = null;
    _cachedPermissions = null;
    _lastActivity = null;

    // Clear ALL secure storage keys
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _isLoggedInKey);
    await _secureStorage.delete(key: _userNameKey);
    await _secureStorage.delete(key: _userEmailKey);
    await _secureStorage.delete(key: _userPhoneKey);
    await _secureStorage.delete(key: _userProfileImageKey);
    await _secureStorage.delete(key: _userMarketIdKey);
    await _secureStorage.delete(key: _isAdminKey);
    await _secureStorage.delete(key: _isSuperAdminKey);

    // Clear SharedPreferences data
    await clearPermissions();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastActivityKey);

    debugPrint('🗑️ All auth data cleared successfully');
  }

  // ==========================================
  // 📊 TOKEN VALIDATION
  // ==========================================

  /// Validate if the token is still valid (not expired)
  Future<bool> isValidToken() async {
    final token = await getAuthToken();
    if (token == null || token.isEmpty) return false;

    try {
      // Decode JWT to check expiration
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = parts[1];
      // Add padding if needed
      String normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }

      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded) as Map<String, dynamic>;

      if (json.containsKey('exp')) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(
          (json['exp'] as int) * 1000,
        );
        return expiry.isAfter(DateTime.now());
      }

      return true;
    } catch (e) {
      debugPrint('⚠️ Token validation failed: $e');
      return false;
    }
  }
}
