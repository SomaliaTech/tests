import 'package:mobile/features/wishlist/domain/repository/wishlist_repository.dart';

import '../../../../core/utils/typedefs.dart';

class IsInWishlist {
  final WishlistRepository repository;

  const IsInWishlist(this.repository);

  ResultFuture<bool> call(String itemId) async {
    return await repository.isInWishlist(itemId);
  }
}
