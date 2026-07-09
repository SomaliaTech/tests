// lib/features/profile/domain/entities/profile.dart
import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String? profileImage;
  final String? marketId;
  final bool isVerified;
  final bool isAdmin; // ✅ Add this
  final bool isSuperAdmin; // ✅ Add this

  const Profile({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.profileImage,
    this.marketId,
    required this.isVerified,
    this.isAdmin = false, // ✅ Default false
    this.isSuperAdmin = false, // ✅ Default false
  });

  @override
  List<Object?> get props => [
    id,
    name,
    phoneNumber,
    email,
    profileImage,
    marketId,
    isVerified,
    isAdmin,
    isSuperAdmin,
  ];
}
