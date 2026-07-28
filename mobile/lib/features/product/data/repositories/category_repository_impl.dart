import 'package:fpdart/fpdart.dart';
import 'package:mobile/features/product/data/datasources/local/category_local_datasource.dart';
import 'package:mobile/features/product/domain/entities/category.dart'; // ✅ Your Category
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;
  final CategoryLocalDataSource localDataSource;

  const CategoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  ResultFuture<List<Category>> getCategories() async {
    try {
      // 🚀 First, load cached categories
      final cachedCategories = await localDataSource.getCachedCategories();

      // Try to fetch fresh data
      try {
        final remoteCategories = await remoteDataSource.getCategories();
        // Cache the fresh data
        await localDataSource.cacheCategories(remoteCategories);
        return Right(remoteCategories);
      } catch (e) {
        // If network fails, return cached data
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

  @override
  ResultFuture<List<Category>> getParentCategories() async {
    try {
      // 🚀 First, load cached parent categories
      final cachedParents = await localDataSource.getCachedParentCategories();

      try {
        final remoteParents = await remoteDataSource.getParentCategories();
        await localDataSource.cacheParentCategories(remoteParents);
        return Right(remoteParents);
      } catch (e) {
        if (cachedParents.isNotEmpty) {
          return Right(cachedParents);
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
  ResultFuture<List<Category>> getSubcategories(String parentId) async {
    try {
      // 🚀 First, load cached subcategories
      final cachedSubs = await localDataSource.getCachedSubcategories(parentId);

      try {
        final remoteSubs = await remoteDataSource.getSubcategories(parentId);
        await localDataSource.cacheSubcategories(parentId, remoteSubs);
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
  ResultFuture<Category> getCategoryById(String id) async {
    try {
      // 🚀 First, check cached category
      final cachedCategory = await localDataSource.getCachedCategory(id);

      try {
        final remoteCategory = await remoteDataSource.getCategoryById(id);
        await localDataSource.cacheCategory(remoteCategory);
        return Right(remoteCategory);
      } catch (e) {
        if (cachedCategory != null) {
          return Right(cachedCategory);
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
  ResultFuture<Category> getCategoryBySlug(String slug) async {
    try {
      final category = await remoteDataSource.getCategoryBySlug(slug);
      await localDataSource.cacheCategory(category);
      return Right(category);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
