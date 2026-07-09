import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _isSuperAdminKey = 'is_super_admin'; // ✅ Already defined
  static const String _messageSoundKey = 'message_sound_enabled';

  final FlutterSecureStorage _secureStorage;

  // ✅ In-memory cache to prevent read delays
  String? _cachedToken;
  bool? _cachedIsSuperAdmin; // ✅ Cache for super admin

  StorageService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // ==========================================
  // Super Admin
  // ==========================================
  Future<void> saveIsSuperAdmin(bool isSuperAdmin) async {
    debugPrint('💾 Saving isSuperAdmin: $isSuperAdmin'); // ✅ Debug
    _cachedIsSuperAdmin = isSuperAdmin;
    await _secureStorage.write(
      key: _isSuperAdminKey,
      value: isSuperAdmin.toString(),
    );
    debugPrint('💾 isSuperAdmin saved successfully');
  }

  Future<void> setChatMuted(String chatId, bool isMuted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('chat_muted_$chatId', isMuted);
  }

  // Get mute status for a specific chat
  Future<bool> isChatMuted(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('chat_muted_$chatId') ?? false;
  }

  Future<bool> getIsSuperAdmin() async {
    debugPrint('🔍 Getting isSuperAdmin from storage...'); // ✅ Debug
    if (_cachedIsSuperAdmin != null) {
      debugPrint('🔍 Cached isSuperAdmin: $_cachedIsSuperAdmin');
      return _cachedIsSuperAdmin!;
    }
    final value = await _secureStorage.read(key: _isSuperAdminKey);
    debugPrint('🔍 Raw isSuperAdmin value: $value'); // ✅ Debug
    final result = value == 'true';
    _cachedIsSuperAdmin = result;
    debugPrint('🔍 Parsed isSuperAdmin: $result'); // ✅ Debug
    return result;
  }

  // ==========================================
  // Auth related
  // ==========================================
  Future<void> saveAuthToken(String token) async {
    _cachedToken = token;
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getAuthToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }

    final token = await _secureStorage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) {
      _cachedToken = token;
    }
    return token;
  }

  Future<void> saveUserId(String userId) async {
    await _secureStorage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  Future<void> saveLoginStatus(bool isLoggedIn) async {
    await _secureStorage.write(
      key: _isLoggedInKey,
      value: isLoggedIn.toString(),
    );
  }

  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    final isLoggedIn = await _secureStorage.read(key: _isLoggedInKey);
    return token != null && token.isNotEmpty && isLoggedIn == 'true';
  }

  // ==========================================
  // Admin related
  // ==========================================
  Future<void> saveIsAdmin(bool isAdmin) async {
    await _secureStorage.write(key: _isAdminKey, value: isAdmin.toString());
  }

  Future<bool> getIsAdmin() async {
    final value = await _secureStorage.read(key: _isAdminKey);
    return value == 'true';
  }

  // ==========================================
  // Profile related
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
  // Sound Settings (uses SharedPreferences)
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
  // Clear Data (Logout)
  // ==========================================
  Future<void> clearAuthData() async {
    _cachedToken = null;
    _cachedIsSuperAdmin = null; // ✅ Clear cache
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _isLoggedInKey);
    await _secureStorage.delete(key: _userNameKey);
    await _secureStorage.delete(key: _userEmailKey);
    await _secureStorage.delete(key: _userPhoneKey);
    await _secureStorage.delete(key: _userProfileImageKey);
    await _secureStorage.delete(key: _userMarketIdKey);
    await _secureStorage.delete(key: _isAdminKey);
    await _secureStorage.delete(key: _isSuperAdminKey); // ✅ Clear super admin
  }
}
