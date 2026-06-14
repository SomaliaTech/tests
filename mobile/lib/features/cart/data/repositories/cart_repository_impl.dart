import 'package:fpdart/fpdart.dart';
import 'package:mobile/features/cart/data/datasources/cart_local_datasource.dart';
import 'package:mobile/features/cart/data/datasources/cart_remote_datasource.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource remoteDataSource;
  final CartLocalDataSource localDataSource;
  final StorageService storageService;

  const CartRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.storageService,
  });

  Future<String?> _getToken() async => await storageService.getAuthToken();

  @override
  ResultFuture<List<CartItem>> getCartItems() async {
    try {
      final token = await _getToken();

      // First, return cached items immediately for instant UI update
      final cachedItems = await localDataSource.getCachedCartItems();

      if (token != null && token.isNotEmpty) {
        // Then fetch from remote and update cache in background
        _syncCartWithRemote(token).catchError((error) {
          print('Background sync failed: $error');
        });
        return Right(cachedItems);
      } else {
        // Not logged in, just return cached items
        return Right(cachedItems);
      }
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  Future<void> _syncCartWithRemote(String token) async {
    try {
      final remoteItems = await remoteDataSource.getCartItems(token);
      await localDataSource.cacheCartItems(remoteItems);
    } catch (e) {
      print('Failed to sync cart: $e');
    }
  }

  @override
  ResultFuture<CartItem> addToCart(
    String productVariantId,
    int quantity,
  ) async {
    try {
      final token = await _getToken();

      if (token != null && token.isNotEmpty) {
        // Send to backend first
        final remoteItem = await remoteDataSource.addToCart(
          token,
          productVariantId,
          quantity,
        );
        // Cache the real item
        await localDataSource.addToCache(remoteItem);
        return Right(remoteItem);
      } else {
        // For guest users, create local item
        final tempItem = CartItem(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          productId: productVariantId,
          productVariantId: productVariantId,
          name: 'Product',
          imageUrl: '',
          price: 0,
          quantity: quantity,
          maxStock: 999,
          inStock: true,
        );
        await localDataSource.addToCache(tempItem);
        return Right(tempItem);
      }
    } catch (e) {
      return Left(ServerFailure('Failed to add to cart: $e'));
    }
  }

  @override
  ResultFuture<CartItem> updateQuantity(String itemId, int quantity) async {
    try {
      final token = await _getToken();

      // Update cache optimistically
      await localDataSource.updateCacheItem(itemId, quantity);

      if (token != null && token.isNotEmpty) {
        final remoteItem = await remoteDataSource.updateCartItem(
          token,
          itemId,
          quantity,
        );
        await localDataSource.updateCacheItem(itemId, quantity);
        return Right(remoteItem);
      } else {
        final items = await localDataSource.getCachedCartItems();
        final item = items.firstWhere((i) => i.id == itemId);
        final updatedItem = CartItem(
          id: item.id,
          productId: item.productId,
          productVariantId: item.productVariantId,
          name: item.name,
          imageUrl: item.imageUrl,
          price: item.price,
          quantity: quantity,
          maxStock: item.maxStock,
          inStock: item.inStock,
          color: item.color,
          size: item.size,
        );
        return Right(updatedItem);
      }
    } catch (e) {
      return Left(ServerFailure('Failed to update quantity: $e'));
    }
  }

  @override
  ResultFuture<void> removeItem(String itemId) async {
    try {
      final token = await _getToken();

      // Remove from cache optimistically
      await localDataSource.removeFromCache(itemId);

      if (token != null && token.isNotEmpty) {
        await remoteDataSource.removeCartItem(token, itemId);
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to remove item: $e'));
    }
  }

  @override
  ResultFuture<void> clearCart() async {
    try {
      final token = await _getToken();

      // Clear cache optimistically
      await localDataSource.clearCache();

      if (token != null && token.isNotEmpty) {
        await remoteDataSource.clearCart(token);
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to clear cart: $e'));
    }
  }
}
