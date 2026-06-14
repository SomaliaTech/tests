import '../../../../core/utils/typedefs.dart';
import '../entities/order_history.dart';

abstract class OrderHistoryRepository {
  ResultFuture<List<OrderHistory>> getOrders();
  ResultFuture<OrderHistory> getOrderById(String orderId);
}
