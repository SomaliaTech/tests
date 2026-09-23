import 'package:mobile/features/admin/domain/entities/affiliate_entity.dart';

class AffiliateModel extends AffiliateEntity {
  const AffiliateModel({
    required super.id,
    required super.userId,
    required super.uniqueCode,
    required super.commissionRate,
    required super.totalEarnings,
    required super.paidEarnings,
    required super.pendingEarnings,
    required super.totalOrders,
    required super.totalCustomers,
    required super.status,
    required super.joinedAt,
    super.userName,
    super.userEmail,
    super.userPhone,
    super.maxDiscountAmount,
    super.maxUsesPerUser,
    super.userProfileImage,
    super.promoCodesCount,
    super.activePromoCodes,
  });

  factory AffiliateModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return AffiliateModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      uniqueCode: json['uniqueCode'] ?? '',
      commissionRate: _parseDouble(json['commissionRate']),
      totalEarnings: _parseDouble(json['totalEarnings']),
      paidEarnings: _parseDouble(json['paidEarnings']),
      pendingEarnings: _parseDouble(json['pendingEarnings']),
      totalOrders: _parseInt(json['totalOrders']),
      totalCustomers: _parseInt(json['totalCustomers']),
      status: json['status'] ?? 'ACTIVE',
      joinedAt: DateTime.parse(
        json['joinedAt'] ?? DateTime.now().toIso8601String(),
      ),
      maxUsesPerUser: json['maxUsesPerUser'] as int?,
      maxDiscountAmount: json['maxDiscountAmount'] != null
          ? double.tryParse(json['maxDiscountAmount'].toString())
          : null,
      userName: user?['name'],
      userEmail: user?['email'],
      userPhone: user?['phoneNumber'],
      userProfileImage: user?['profileImage'],
      promoCodesCount: _parseInt(json['promoCodesCount']),
      activePromoCodes: _parseInt(json['activePromoCodes']),
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
