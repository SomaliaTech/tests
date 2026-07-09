import 'package:equatable/equatable.dart';

class AdminUserEntity extends Equatable {
  final String id;
  final String phoneNumber;
  final String? name;
  final String? email;
  final String? profileImage;
  final String? marketId;
  final bool isVerified;
  final bool isAdmin;
  final DateTime createdAt;
  final bool? isSuperAdmin; // ✅ ADD THIS
  final DateTime updatedAt;

  const AdminUserEntity({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.email,
    this.profileImage,
    this.marketId,
    this.isSuperAdmin, // ✅ ADD THIS
    required this.isVerified,
    required this.isAdmin,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    phoneNumber,
    name,
    email,
    profileImage,
    marketId,
    isVerified,
    isAdmin,
    createdAt,
    updatedAt,
  ];
}
