import '../../domain/entities/profile.dart';

class ProfileModel {
  const ProfileModel._();

  static Profile fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String,
      profileImage: json['profileImage'] as String?,
      marketId: json['marketId'] as String?,
      marketName: json['marketName'] as String?,
    );
  }
}
