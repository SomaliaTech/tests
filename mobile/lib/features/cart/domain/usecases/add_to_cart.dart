import '../../../../core/utils/typedefs.dart';
import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

class AddToCart {
  final CartRepository repository;
  const AddToCart(this.repository);

  // 🚨 FIXED: Changed return type to void and parameter to CartItem
  ResultFuture<void> call(CartItem item) => repository.addToCart(item);
}
