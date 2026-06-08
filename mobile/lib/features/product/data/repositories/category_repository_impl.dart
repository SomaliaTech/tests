import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;

  const CategoryRepositoryImpl({required this.remoteDataSource});

  @override
  ResultFuture<List<Category>> getCategories() async {
    try {
      final categories = await remoteDataSource.getCategories();
      return Right(categories);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<List<Category>> getParentCategories() async {
    try {
      final categories = await remoteDataSource.getParentCategories();
      return Right(categories);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<List<Category>> getSubcategories(String parentId) async {
    try {
      final subcategories = await remoteDataSource.getSubcategories(parentId);
      return Right(subcategories);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<Category> getCategoryById(String id) async {
    try {
      final category = await remoteDataSource.getCategoryById(id);
      return Right(category);
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
      return Right(category);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
