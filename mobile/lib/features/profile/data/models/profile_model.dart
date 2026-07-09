// lib/features/profile/data/models/profile_model.dart
import '../../domain/entities/profile.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.id,
    required super.name,
    required super.phoneNumber,
    super.email,
    super.profileImage,
    super.marketId,
    required super.isVerified,
    super.isAdmin,
    super.isSuperAdmin,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      email: json['email'] as String?,
      profileImage: json['profileImage'] as String?,
      marketId: json['marketId'] as String?,
      isVerified: json['isVerified'] == true,
      isAdmin: json['isAdmin'] == true, // ✅ Parse admin
      isSuperAdmin: json['isSuperAdmin'] == true, // ✅ Parse super admin
    );
  }
}
