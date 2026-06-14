import '../../../../core/utils/typedefs.dart';
import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

class AddToCart {
  final CartRepository repository;
  const AddToCart(this.repository);
  ResultFuture<CartItem> call(String productVariantId, int quantity) =>
      repository.addToCart(productVariantId, quantity);
}
