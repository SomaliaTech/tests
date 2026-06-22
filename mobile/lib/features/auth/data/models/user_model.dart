import '../../domain/entities/user.dart';

class UserModel {
  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phoneNumber: json['phoneNumber'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      profileImage: json['profileImage'] as String?,
      marketId: json['marketId'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      hasProfile: json['hasProfile'] as bool? ?? false,
      isAdmin: json['isAdmin'] as bool? ?? false, //  ENSURE THIS IS HERE
    );
  }
}
