import '../../../../core/utils/typedefs.dart';
import '../entities/order_history.dart';
import '../repositories/order_history_repository.dart';

class GetOrders {
  final OrderHistoryRepository repository;
  const GetOrders(this.repository);
  ResultFuture<List<OrderHistory>> call() => repository.getOrders();
}
