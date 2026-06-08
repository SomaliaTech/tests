import 'package:mobile/features/wishlist/domain/repository/wishlist_repository.dart';

import '../../../../core/utils/typedefs.dart';

class RemoveFromWishlist {
  final WishlistRepository repository;

  const RemoveFromWishlist(this.repository);

  ResultFuture<void> call(String itemId) async {
    return await repository.removeFromWishlist(itemId);
  }
}
