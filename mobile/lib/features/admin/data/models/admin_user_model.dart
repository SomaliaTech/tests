import '../../domain/entities/admin_user_entity.dart';

class AdminUserModel extends AdminUserEntity {
  const AdminUserModel({
    required super.id,
    required super.phoneNumber,
    super.name,
    super.email,
    super.profileImage,
    super.marketId,
    required super.isVerified,
    required super.isAdmin,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      name: json['name'],
      email: json['email'],
      profileImage: json['profileImage'],
      marketId: json['marketId'],
      isVerified: json['isVerified'] ?? false,
      isAdmin: json['isAdmin'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'marketId': marketId,
      'isVerified': isVerified,
      'isAdmin': isAdmin,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
