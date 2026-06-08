import 'package:get_it/get_it.dart';
import 'package:mobile/features/product/data/datasources/category_remote_datasource.dart';
import 'package:mobile/features/product/data/repositories/category_repository_impl.dart';
import 'package:mobile/features/product/domain/repositories/category_repository.dart';
import 'package:mobile/features/product/domain/usecases/get_categories.dart';
import 'package:mobile/features/product/domain/usecases/get_category_by_id.dart';
import 'package:mobile/features/product/domain/usecases/get_parent_categories.dart';
import 'package:mobile/features/product/domain/usecases/get_subcategories.dart';
import 'package:mobile/features/product/presentation/blocs/category_bloc.dart';

void registerCategoryDependencies(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSourceImpl(client: sl()),
  );

  // Repositories
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases (Shared across the app)
  sl.registerLazySingleton(() => GetCategories(sl()));
  sl.registerLazySingleton(() => GetSubcategories(sl()));
  sl.registerLazySingleton(() => GetParentCategories(sl()));
  sl.registerLazySingleton(() => GetCategoryById(sl()));

  // BLoC
  sl.registerFactory(
    () => CategoryBloc(
      getCategories: sl(),
      getParentCategories: sl(),
      getSubcategories: sl(),
      getCategoryById: sl(),
    ),
  );
}
