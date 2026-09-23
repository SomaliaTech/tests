import 'package:equatable/equatable.dart';

class AffiliateEntity extends Equatable {
  final String id;
  final String userId;
  final String uniqueCode;
  final double commissionRate;
  final double totalEarnings;
  final double paidEarnings;
  final double pendingEarnings;
  final int totalOrders;
  final int totalCustomers;
  final String status; // ACTIVE, SUSPENDED
  final DateTime joinedAt;
  final int? maxUsesPerUser;
  final double? maxDiscountAmount;
  // Joined user info
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? userProfileImage;

  // Extra counts
  final int? promoCodesCount;
  final int? activePromoCodes;

  const AffiliateEntity({
    required this.id,
    required this.userId,
    required this.uniqueCode,
    required this.commissionRate,
    required this.totalEarnings,
    required this.paidEarnings,
    required this.pendingEarnings,
    required this.totalOrders,
    required this.totalCustomers,
    required this.status,
    required this.joinedAt,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.maxDiscountAmount,
    this.maxUsesPerUser,
    this.userProfileImage,
    this.promoCodesCount,
    this.activePromoCodes,
  });

  @override
  List<Object?> get props => [id];
}
