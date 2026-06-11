import '../../../../core/utils/typedefs.dart';
import '../entities/order.dart' as domain;

abstract class OrderRepository {
  ResultFuture<domain.DomainOrder> createOrder(Map<String, dynamic> orderData);
  ResultFuture<Map<String, dynamic>> processPayment(
    String orderId,
    String paymentMethod, {
    String? phoneNumber,
  });
}
