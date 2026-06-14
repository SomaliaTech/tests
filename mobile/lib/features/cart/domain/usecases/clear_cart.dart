import '../../../../core/utils/typedefs.dart';
import '../repositories/cart_repository.dart';

class ClearCart {
  final CartRepository repository;
  const ClearCart(this.repository);
  ResultFuture<void> call() => repository.clearCart();
}
