import '../../../../core/utils/typedefs.dart';
import '../entities/order_details.dart';
import '../repositories/order_details_repository.dart';

class GetOrderDetails {
  final OrderDetailsRepository repository;
  const GetOrderDetails(this.repository);
  ResultFuture<OrderDetails> call(String orderId) =>
      repository.getOrderDetails(orderId);
}
