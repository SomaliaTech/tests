import 'package:flutter/material.dart';
import '../../data/models/profile_model.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileData _profile = const ProfileData(
    name: 'Eng Soke',
    phone: '252616739858',
    market: null,
    profileImage: null,
    points: 1250,
  );

  bool _isUpdating = false;
  bool _isMarketDropdownOpen = false;

  ProfileData get profile => _profile;
  bool get isUpdating => _isUpdating;
  bool get isMarketDropdownOpen => _isMarketDropdownOpen;

  List<Market> get markets => Market.values;

  void updateName(String name) {
    _profile = _profile.copyWith(name: name);
    notifyListeners();
  }

  void updateMarket(Market? market) {
    _profile = _profile.copyWith(market: market);
    notifyListeners();
  }

  void updateProfileImage(String? imagePath) {
    _profile = _profile.copyWith(profileImage: imagePath);
    notifyListeners();
  }

  void toggleMarketDropdown() {
    _isMarketDropdownOpen = !_isMarketDropdownOpen;
    notifyListeners();
  }

  void closeMarketDropdown() {
    _isMarketDropdownOpen = false;
    notifyListeners();
  }

  Future<bool> updateProfile() async {
    if (_profile.name.trim().isEmpty) {
      return false;
    }
    if (_profile.market == null) {
      return false;
    }

    _isUpdating = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    _isUpdating = false;
    notifyListeners();

    return true;
  }

  Future<void> logout() async {
    // Clear session/state
    _profile = const ProfileData(
      name: '',
      phone: '',
      market: null,
      profileImage: null,
      points: 0,
    );
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> deleteAccount() async {
    // Handle account deletion
    debugPrint('Account deleted');
    await Future.delayed(const Duration(seconds: 1));
  }

  void inviteFriends() {
    debugPrint('Invite friends');
  }

  void contactWhatsApp() {
    debugPrint('Contact WhatsApp');
  }
}
