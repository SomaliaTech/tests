import '../../../../core/utils/typedefs.dart';
import '../entities/wishlist_item.dart';

abstract class WishlistRepository {
  ResultFuture<List<WishlistItem>> getWishlistItems();
  ResultFuture<void> addToWishlist(WishlistItem item);
  ResultFuture<void> removeFromWishlist(String itemId);
  ResultFuture<void> clearWishlist();
  ResultFuture<bool> isInWishlist(String itemId);
}
