// lib/features/order/domain/usecases/create_order.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/order_repository.dart';

class CreateOrder {
  final OrderRepository repository;

  CreateOrder(this.repository);

  // ✅ Return Map instead of DomainOrder since backend now returns full response
  ResultFuture<Map<String, dynamic>> call(Map<String, dynamic> orderData) {
    return repository.createOrder(orderData);
  }
}
