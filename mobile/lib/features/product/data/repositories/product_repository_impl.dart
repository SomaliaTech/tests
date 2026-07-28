// lib/features/product/data/repositories/product_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import 'package:mobile/features/product/data/datasources/local/category_local_datasource.dart';
import 'package:mobile/features/product/domain/entities/category.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/local/product_local_datasource.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;
  final CategoryLocalDataSource categoryLocalDataSource; // ✅ Add this

  const ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.categoryLocalDataSource, // ✅ Add this
  });

  // ✅ Add getCategories implementation
  @override
  ResultFuture<List<Category>> getCategories() async {
    try {
      final cachedCategories = await categoryLocalDataSource
          .getCachedCategories();
      try {
        // Fetch from product remote or category remote
        final remoteCategories = await remoteDataSource.getCategories();
        await categoryLocalDataSource.cacheCategories(remoteCategories);
        return Right(remoteCategories);
      } catch (e) {
        if (cachedCategories.isNotEmpty) {
          return Right(cachedCategories);
        }
        rethrow;
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  // ✅ Add getSubcategories implementation
  @override
  ResultFuture<List<Category>> getSubcategories(String parentId) async {
    try {
      final cachedSubs = await categoryLocalDataSource.getCachedSubcategories(
        parentId,
      );
      try {
        final remoteSubs = await remoteDataSource.getSubcategories(parentId);
        await categoryLocalDataSource.cacheSubcategories(parentId, remoteSubs);
        return Right(remoteSubs);
      } catch (e) {
        if (cachedSubs.isNotEmpty) {
          return Right(cachedSubs);
        }
        rethrow;
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<List<Product>> getFeaturedProducts({int limit = 10}) async {
    try {
      final cachedProducts = await localDataSource.getCachedFeaturedProducts();
      try {
        final remoteProducts = await remoteDataSource.getFeaturedProducts(
          limit: limit,
        );
        await localDataSource.cacheFeaturedProducts(remoteProducts);
        return Right(remoteProducts);
      } catch (e) {
        if (cachedProducts.isNotEmpty) {
          return Right(cachedProducts);
        }
        rethrow;
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final cachedProducts = await localDataSource.getCachedProductsByCategory(
        categoryId,
      );
      try {
        final remoteProducts = await remoteDataSource.getProductsByCategory(
          categoryId,
        );
        await localDataSource.cacheProductsByCategory(
          categoryId,
          remoteProducts,
        );
        return Right(remoteProducts);
      } catch (e) {
        if (cachedProducts.isNotEmpty) {
          return Right(cachedProducts);
        }
        rethrow;
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<List<Product>> searchProducts({
    String? query,
    double? minPrice,
    double? maxPrice,
    String? categoryId,
    String? sortBy,
  }) async {
    try {
      final products = await remoteDataSource.searchProducts(
        query: query,
        minPrice: minPrice,
        maxPrice: maxPrice,
        categoryId: categoryId,
        sortBy: sortBy,
      );
      return Right(products);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<Product> getProductById(String id) async {
    try {
      final cachedProduct = await localDataSource.getCachedProduct(id);
      try {
        final remoteProduct = await remoteDataSource.getProductById(id);
        await localDataSource.cacheProduct(remoteProduct);
        return Right(remoteProduct);
      } catch (e) {
        if (cachedProduct != null) {
          return Right(cachedProduct);
        }
        rethrow;
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<Product> getProductBySlug(String slug) async {
    try {
      final product = await remoteDataSource.getProductBySlug(slug);
      await localDataSource.cacheProduct(product);
      return Right(product);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
