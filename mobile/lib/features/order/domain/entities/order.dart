import 'package:equatable/equatable.dart';

// Renamed to DomainOrder to avoid conflict with fpdart.Order
class DomainOrder extends Equatable {
  final String id;
  final String orderNumber;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final DateTime createdAt;

  const DomainOrder({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    totalAmount,
    status,
    paymentStatus,
    createdAt,
  ];
}
