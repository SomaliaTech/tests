import '../../../../core/utils/typedefs.dart';
import '../repositories/cart_repository.dart';

class UpdateQuantity {
  final CartRepository repository;
  const UpdateQuantity(this.repository);

  // 🚨 FIXED: Changed return type from CartItem to void
  ResultFuture<void> call(String itemId, int quantity) =>
      repository.updateQuantity(itemId, quantity);
}
