import 'package:equatable/equatable.dart';

class AffiliateRequestEntity extends Equatable {
  final String id;
  final String userId;
  final String businessName;
  final String? description;
  final String? phoneNumber;
  final Map<String, dynamic>? socialMediaLinks;
  final int? expectedAudience;
  final String status; // PENDING, APPROVED, REJECTED
  final String? rejectionReason;
  final DateTime appliedAt;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  // Joined user info
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? userProfileImage;

  const AffiliateRequestEntity({
    required this.id,
    required this.userId,
    required this.businessName,
    this.description,
    this.phoneNumber,
    this.socialMediaLinks,
    this.expectedAudience,
    required this.status,
    this.rejectionReason,
    required this.appliedAt,
    this.reviewedAt,
    required this.createdAt,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.userProfileImage,
  });

  @override
  List<Object?> get props => [id];
}
