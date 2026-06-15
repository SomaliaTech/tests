import '../../domain/entities/profile.dart';

class ProfileModel {
  const ProfileModel._();

  static Profile fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      email: json['email'] as String?,
      profileImage: json['profileImage'] as String?,
      marketId: json['marketId'] as String?,
      marketName: json['marketName'] as String?,
    );
  }

  static Map<String, dynamic> toJson(Profile profile) {
    return {
      'id': profile.id,
      'name': profile.name,
      'phoneNumber': profile.phoneNumber,
      'email': profile.email,
      'profileImage': profile.profileImage,
      'marketId': profile.marketId,
      'marketName': profile.marketName,
    };
  }
}
