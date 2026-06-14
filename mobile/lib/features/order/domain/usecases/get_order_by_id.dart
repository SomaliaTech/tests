import '../../../../core/utils/typedefs.dart';
import '../entities/order_history.dart';
import '../repositories/order_history_repository.dart';

class GetOrderById {
  final OrderHistoryRepository repository;
  const GetOrderById(this.repository);
  ResultFuture<OrderHistory> call(String orderId) =>
      repository.getOrderById(orderId);
}
