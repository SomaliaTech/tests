import '../../domain/entities/order.dart' as domain;

class OrderModel {
  const OrderModel._();

  static domain.DomainOrder fromJson(Map<String, dynamic> json) {
    return domain.DomainOrder(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      totalAmount: double.parse(json['totalAmount'] as String),
      status: json['status'] as String,
      paymentStatus: json['paymentStatus'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
