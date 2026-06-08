import 'package:mobile/features/wishlist/domain/repository/wishlist_repository.dart';

import '../../../../core/utils/typedefs.dart';
import '../entities/wishlist_item.dart';

class AddToWishlist {
  final WishlistRepository repository;

  const AddToWishlist(this.repository);

  ResultFuture<void> call(WishlistItem item) async {
    return await repository.addToWishlist(item);
  }
}
