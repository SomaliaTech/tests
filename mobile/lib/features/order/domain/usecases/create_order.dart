import '../../../../core/utils/typedefs.dart';
import '../entities/order.dart' as domain;
import '../repositories/order_repository.dart';

class CreateOrder {
  final OrderRepository repository;
  const CreateOrder(this.repository);
  ResultFuture<domain.DomainOrder> call(Map<String, dynamic> orderData) =>
      repository.createOrder(orderData);
}
