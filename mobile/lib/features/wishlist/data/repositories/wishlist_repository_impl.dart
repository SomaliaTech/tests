import 'package:fpdart/fpdart.dart';
import 'package:mobile/features/wishlist/data/model/wishlist_item_model.dart';
import 'package:mobile/features/wishlist/domain/repository/wishlist_repository.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/wishlist_item.dart';
import '../datasources/wishlist_local_datasource.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistLocalDataSource localDataSource;

  const WishlistRepositoryImpl({required this.localDataSource});

  @override
  ResultFuture<List<WishlistItem>> getWishlistItems() async {
    try {
      final items = await localDataSource.getWishlistItems();
      return Right(items);
    } catch (e) {
      return Left(CacheFailure('Failed to load wishlist: $e'));
    }
  }

  @override
  ResultFuture<void> addToWishlist(WishlistItem item) async {
    try {
      final model = WishlistItemModel(
        id: item.id,
        name: item.name,
        price: item.price,
        imageUrl: item.imageUrl,
        brand: item.brand,
        rating: item.rating,
        categoryId: item.categoryId,
      );
      await localDataSource.addItem(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to add to wishlist: $e'));
    }
  }

  @override
  ResultFuture<void> removeFromWishlist(String itemId) async {
    try {
      await localDataSource.removeItem(itemId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to remove from wishlist: $e'));
    }
  }

  @override
  ResultFuture<void> clearWishlist() async {
    try {
      await localDataSource.clearItems();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to clear wishlist: $e'));
    }
  }

  @override
  ResultFuture<bool> isInWishlist(String itemId) async {
    try {
      final isIn = await localDataSource.isInWishlist(itemId);
      return Right(isIn);
    } catch (e) {
      return Left(CacheFailure('Failed to check wishlist: $e'));
    }
  }
}
