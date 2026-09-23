import 'package:mobile/features/admin/domain/entities/affiliate_request_entity.dart';

class AffiliateRequestModel extends AffiliateRequestEntity {
  const AffiliateRequestModel({
    required super.id,
    required super.userId,
    required super.businessName,
    super.description,
    super.phoneNumber,
    super.socialMediaLinks,
    super.expectedAudience,
    required super.status,
    super.rejectionReason,
    required super.appliedAt,
    super.reviewedAt,
    required super.createdAt,
    super.userName,
    super.userEmail,
    super.userPhone,
    super.userProfileImage,
  });

  factory AffiliateRequestModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return AffiliateRequestModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      businessName: json['businessName'] ?? '',
      description: json['description'],
      phoneNumber: json['phoneNumber'],
      socialMediaLinks: json['socialMediaLinks'] is Map
          ? Map<String, dynamic>.from(json['socialMediaLinks'])
          : null,
      expectedAudience: json['expectedAudience'],
      status: json['status'] ?? 'PENDING',
      rejectionReason: json['rejectionReason'],
      appliedAt: DateTime.parse(
        json['appliedAt'] ?? DateTime.now().toIso8601String(),
      ),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'])
          : null,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      userName: user?['name'],
      userEmail: user?['email'],
      userPhone: user?['phoneNumber'],
      userProfileImage: user?['profileImage'],
    );
  }
}
