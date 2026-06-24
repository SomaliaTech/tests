import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_datasource.dart';

class CartRepositoryImpl implements CartRepository {
  final CartLocalDataSource localDataSource;

  const CartRepositoryImpl({required this.localDataSource});

  @override
  ResultFuture<List<CartItem>> getCartItems() async {
    try {
      final items = await localDataSource.getCachedCartItems();
      return Right(items);
    } catch (e) {
      return Left(ServerFailure('Failed to load cart: $e'));
    }
  }

  @override
  ResultFuture<void> addToCart(CartItem item) async {
    try {
      await localDataSource.addToCache(item);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to add to cart: $e'));
    }
  }

  @override
  ResultFuture<void> updateQuantity(String itemId, int quantity) async {
    try {
      await localDataSource.updateCacheItem(itemId, quantity);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to update quantity: $e'));
    }
  }

  // 🚨 FIXED: Pass productVariantId to the data source
  @override
  ResultFuture<void> removeItem(String productVariantId) async {
    try {
      await localDataSource.removeFromCart(productVariantId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to remove item: $e'));
    }
  }

  @override
  ResultFuture<void> clearCart() async {
    try {
      await localDataSource.clearCache();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to clear cart: $e'));
    }
  }
}
