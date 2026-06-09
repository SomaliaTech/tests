import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';
  static const String _userProfileImageKey = 'user_profile_image';
  static const String _userMarketIdKey = 'user_market_id';

  final FlutterSecureStorage _secureStorage;

  StorageService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // Auth related
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: _tokenKey);
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

  // Profile related
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

  Future<void> clearAuthData() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _isLoggedInKey);
    await _secureStorage.delete(key: _userNameKey);
    await _secureStorage.delete(key: _userEmailKey);
    await _secureStorage.delete(key: _userPhoneKey);
    await _secureStorage.delete(key: _userProfileImageKey);
    await _secureStorage.delete(key: _userMarketIdKey);
  }
}
