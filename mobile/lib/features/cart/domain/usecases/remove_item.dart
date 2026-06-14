import '../../../../core/utils/typedefs.dart';
import '../repositories/cart_repository.dart';

class RemoveItem {
  final CartRepository repository;
  const RemoveItem(this.repository);
  ResultFuture<void> call(String itemId) => repository.removeItem(itemId);
}
