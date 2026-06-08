import 'package:mobile/features/wishlist/domain/repository/wishlist_repository.dart';

import '../../../../core/utils/typedefs.dart';

class ClearWishlist {
  final WishlistRepository repository;

  const ClearWishlist(this.repository);

  ResultFuture<void> call() async {
    return await repository.clearWishlist();
  }
}
