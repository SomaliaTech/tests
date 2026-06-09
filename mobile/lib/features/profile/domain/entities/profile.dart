import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String? profileImage;
  final String? marketId;
  final String? marketName;

  const Profile({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.profileImage,
    this.marketId,
    this.marketName,
  });

  bool get hasProfile => name.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    name,
    phoneNumber,
    email,
    profileImage,
    marketId,
    marketName,
  ];
}
