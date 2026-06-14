import '../../../../core/utils/typedefs.dart';
import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

class UpdateQuantity {
  final CartRepository repository;
  const UpdateQuantity(this.repository);
  ResultFuture<CartItem> call(String itemId, int quantity) =>
      repository.updateQuantity(itemId, quantity);
}
