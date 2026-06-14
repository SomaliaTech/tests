import 'package:mobile/features/order/domain/entities/order.dart';

class OrderModel {
  const OrderModel._();

  static DomainOrder fromJson(Map<String, dynamic> json) {
    return DomainOrder(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      totalAmount: double.parse(json['totalAmount'] as String),
      status: json['status'] as String,
      paymentStatus: json['paymentStatus'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
