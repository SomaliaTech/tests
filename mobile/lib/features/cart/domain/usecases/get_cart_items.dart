import '../../../../core/utils/typedefs.dart';
import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

class GetCartItems {
  final CartRepository repository;
  const GetCartItems(this.repository);
  ResultFuture<List<CartItem>> call() => repository.getCartItems();
}
