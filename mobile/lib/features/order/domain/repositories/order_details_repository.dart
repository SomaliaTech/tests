import '../../../../core/utils/typedefs.dart';
import '../entities/order_details.dart';

abstract class OrderDetailsRepository {
  ResultFuture<OrderDetails> getOrderDetails(String orderId);
}
