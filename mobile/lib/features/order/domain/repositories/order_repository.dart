// lib/features/order/domain/repositories/order_repository.dart
import '../../../../core/utils/typedefs.dart';

abstract class OrderRepository {
  ResultFuture<Map<String, dynamic>> createOrder(
    Map<String, dynamic> orderData,
  );
}
