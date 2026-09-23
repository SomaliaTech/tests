import 'package:mobile/features/admin/domain/entities/affiliate_commission_entity.dart';

class AffiliateCommissionModel extends AffiliateCommissionEntity {
  const AffiliateCommissionModel({
    required super.id,
    required super.affiliateId,
    super.orderId,
    required super.commissionRate,
    required super.commissionAmount,
    required super.orderAmount,
    required super.status,
    super.paidAt,
    required super.createdAt,
    super.affiliateCode,
    super.affiliateName,
    super.affiliatePhone,
    super.orderNumber,
  });

  factory AffiliateCommissionModel.fromJson(Map<String, dynamic> json) {
    return AffiliateCommissionModel(
      id: json['id'] ?? '',
      affiliateId: json['affiliateId'] ?? '',
      orderId: json['orderId'],
      commissionRate: _parseDouble(json['commissionRate']),
      commissionAmount: _parseDouble(json['commissionAmount']),
      orderAmount: _parseDouble(json['orderAmount']),
      status: json['status'] ?? 'PENDING',
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      affiliateCode: json['affiliateCode'],
      affiliateName: json['affiliateName'],
      affiliatePhone: json['affiliatePhone'],
      orderNumber: json['orderNumber'],
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
