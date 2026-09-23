import 'package:equatable/equatable.dart';

class AffiliateCommissionEntity extends Equatable {
  final String id;
  final String affiliateId;
  final String? orderId;
  final double commissionRate;
  final double commissionAmount;
  final double orderAmount;
  final String status; // PENDING, PAID, CANCELLED
  final DateTime? paidAt;
  final DateTime createdAt;

  // Joined info
  final String? affiliateCode;
  final String? affiliateName;
  final String? affiliatePhone;
  final String? orderNumber;

  const AffiliateCommissionEntity({
    required this.id,
    required this.affiliateId,
    this.orderId,
    required this.commissionRate,
    required this.commissionAmount,
    required this.orderAmount,
    required this.status,
    this.paidAt,
    required this.createdAt,
    this.affiliateCode,
    this.affiliateName,
    this.affiliatePhone,
    this.orderNumber,
  });

  @override
  List<Object?> get props => [id];
}
