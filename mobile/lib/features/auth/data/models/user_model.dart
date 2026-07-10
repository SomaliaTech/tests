import '../../domain/entities/user.dart';

class UserModel {
  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phoneNumber: json['phoneNumber'] as String,
      name: json['name'] as String?,
      profileImage: json['profileImage'] as String?,
      marketId: json['marketId'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      hasProfile: json['hasProfile'] as bool? ?? false,
      isAdmin: json['isAdmin'] as bool? ?? false,
      isSuperAdmin: json['isSuperAdmin'] as bool? ?? false, // ✅ ADDED
    );
  }

  static Map<String, dynamic> toJson(User user) {
    return {
      'id': user.id,
      'phoneNumber': user.phoneNumber,
      'name': user.name,
      'profileImage': user.profileImage,
      'marketId': user.marketId,
      'isVerified': user.isVerified,
      'hasProfile': user.hasProfile,
      'isAdmin': user.isAdmin,
      'isSuperAdmin': user.isSuperAdmin, // ✅ ADDED
    };
  }
}
