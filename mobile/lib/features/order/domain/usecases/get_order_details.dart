import '../../../../core/utils/typedefs.dart';
import '../entities/order_details.dart';
import '../repositories/order_details_repository.dart';

class GetOrderDetails {
  final OrderDetailsRepository repository;
  const GetOrderDetails(this.repository);

  ResultFuture<OrderDetails> call(
    String orderId, {
    bool isAdmin = false,
    bool isSuperAdmin = false,
  }) => repository.getOrderDetails(
    orderId,
    isAdmin: isAdmin,
    isSuperAdmin: isSuperAdmin,
  );
}
