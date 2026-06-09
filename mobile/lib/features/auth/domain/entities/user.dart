// lib/features/auth/domain/entities/user.dart
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String phoneNumber;
  final String? name;
  final String? email;
  final String? profileImage;
  final bool isVerified;
  final bool hasProfile;

  const User({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.email,
    this.profileImage,
    this.isVerified = false,
    this.hasProfile = false,
  });

  @override
  List<Object?> get props => [
    id,
    phoneNumber,
    name,
    email,
    profileImage,
    isVerified,
    hasProfile,
  ];
}
