import '../../../../core/utils/typedefs.dart';
import '../repositories/order_repository.dart';

class ProcessPayment {
  final OrderRepository repository;
  const ProcessPayment(this.repository);
  ResultFuture<Map<String, dynamic>> call(
    String orderId,
    String paymentMethod, {
    String? phoneNumber,
  }) => repository.processPayment(
    orderId,
    paymentMethod,
    phoneNumber: phoneNumber,
  );
}
