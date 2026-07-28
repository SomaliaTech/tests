// lib/core/services/category_injection.dart
import 'package:get_it/get_it.dart';
import 'package:mobile/features/product/data/datasources/local/category_local_datasource.dart';
import 'package:mobile/features/product/data/datasources/category_remote_datasource.dart';
import 'package:mobile/features/product/data/repositories/category_repository_impl.dart';
import 'package:mobile/features/product/domain/repositories/category_repository.dart';
import 'package:mobile/features/product/domain/usecases/get_categories.dart';
import 'package:mobile/features/product/domain/usecases/get_category_by_id.dart';
import 'package:mobile/features/product/domain/usecases/get_parent_categories.dart';
import 'package:mobile/features/product/domain/usecases/get_subcategories.dart';
import 'package:mobile/features/product/presentation/blocs/category_bloc.dart';

void registerCategoryDependencies(GetIt sl) {
  // Local Data Source
  if (!sl.isRegistered<CategoryLocalDataSource>()) {
    sl.registerLazySingleton<CategoryLocalDataSource>(
      () => CategoryLocalDataSourceImpl(),
    );
  }

  // Remote Data Source
  if (!sl.isRegistered<CategoryRemoteDataSource>()) {
    sl.registerLazySingleton<CategoryRemoteDataSource>(
      () => CategoryRemoteDataSourceImpl(client: sl()),
    );
  }

  // Repository
  if (!sl.isRegistered<CategoryRepository>()) {
    sl.registerLazySingleton<CategoryRepository>(
      () => CategoryRepositoryImpl(
        remoteDataSource: sl<CategoryRemoteDataSource>(),
        localDataSource: sl<CategoryLocalDataSource>(),
      ),
    );
  }

  // Use Cases
  if (!sl.isRegistered<GetCategories>()) {
    sl.registerLazySingleton(() => GetCategories(sl()));
  }
  if (!sl.isRegistered<GetSubcategories>()) {
    sl.registerLazySingleton(() => GetSubcategories(sl()));
  }
  if (!sl.isRegistered<GetParentCategories>()) {
    sl.registerLazySingleton(() => GetParentCategories(sl()));
  }
  if (!sl.isRegistered<GetCategoryById>()) {
    sl.registerLazySingleton(() => GetCategoryById(sl()));
  }

  // BLoC
  if (!sl.isRegistered<CategoryBloc>()) {
    sl.registerFactory(
      () => CategoryBloc(
        getCategories: sl(),
        getParentCategories: sl(),
        getSubcategories: sl(),
        getCategoryById: sl(),
      ),
    );
  }
}
