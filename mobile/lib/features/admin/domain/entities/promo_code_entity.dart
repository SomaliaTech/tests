import 'package:equatable/equatable.dart';

class PromoCodeEntity extends Equatable {
  final String id;
  final String code;
  final String? description;
  final String discountType; // PERCENTAGE, FIXED
  final double discountValue;
  final double? minOrderAmount;
  final double? maxDiscountAmount;
  final int? maxUses;
  final int usedCount;
  final int maxUsesPerUser;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;

  // Affiliate info (null = system-wide)
  final String? affiliateId;
  final String? affiliateCode;
  final String? affiliateName;

  // Usage stats
  final double? totalRevenue;
  final double? totalDiscountGiven;

  const PromoCodeEntity({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount,
    this.maxDiscountAmount,
    this.maxUses,
    required this.usedCount,
    required this.maxUsesPerUser,
    required this.isActive,
    this.expiresAt,
    required this.createdAt,
    this.affiliateId,
    this.affiliateCode,
    this.affiliateName,
    this.totalRevenue,
    this.totalDiscountGiven,
  });

  @override
  List<Object?> get props => [id];
}
