import 'package:mobile/features/admin/domain/entities/promo_code_entity.dart';

class PromoCodeModel extends PromoCodeEntity {
  const PromoCodeModel({
    required super.id,
    required super.code,
    super.description,
    required super.discountType,
    required super.discountValue,
    super.minOrderAmount,
    super.maxDiscountAmount,
    super.maxUses,
    required super.usedCount,
    required super.maxUsesPerUser,
    required super.isActive,
    super.expiresAt,
    required super.createdAt,
    super.affiliateId,
    super.affiliateCode,
    super.affiliateName,
    super.totalRevenue,
    super.totalDiscountGiven,
  });

  factory PromoCodeModel.fromJson(Map<String, dynamic> json) {
    return PromoCodeModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      description: json['description'],
      discountType: json['discountType'] ?? 'FIXED',
      discountValue: _parseDouble(json['discountValue']),
      minOrderAmount: json['minOrderAmount'] != null
          ? _parseDouble(json['minOrderAmount'])
          : null,
      maxDiscountAmount: json['maxDiscountAmount'] != null
          ? _parseDouble(json['maxDiscountAmount'])
          : null,
      maxUses: json['maxUses'],
      usedCount: _parseInt(json['usedCount']),
      maxUsesPerUser: _parseInt(json['maxUsesPerUser']),
      isActive: json['isActive'] ?? true,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      affiliateId: json['affiliateId'],
      affiliateCode: json['affiliateCode'],
      affiliateName: json['affiliateName'],
      totalRevenue: json['totalRevenue'] != null
          ? _parseDouble(json['totalRevenue'])
          : null,
      totalDiscountGiven: json['totalDiscountGiven'] != null
          ? _parseDouble(json['totalDiscountGiven'])
          : null,
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
