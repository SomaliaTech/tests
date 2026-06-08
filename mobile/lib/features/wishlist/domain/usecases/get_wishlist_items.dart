import 'package:mobile/features/wishlist/domain/repository/wishlist_repository.dart';

import '../../../../core/utils/typedefs.dart';
import '../entities/wishlist_item.dart';

class GetWishlistItems {
  final WishlistRepository repository;

  const GetWishlistItems(this.repository);

  ResultFuture<List<WishlistItem>> call() async {
    return await repository.getWishlistItems();
  }
}
