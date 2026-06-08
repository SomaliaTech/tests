import 'package:get_it/get_it.dart';
import '../../features/product/data/datasources/product_remote_datasource.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';
import '../../features/product/domain/repositories/product_repository.dart';
import '../../features/product/domain/usecases/get_categories.dart';
import '../../features/product/domain/usecases/get_featured_products.dart';
import '../../features/product/domain/usecases/get_product_by_id.dart';
import '../../features/product/domain/usecases/get_products_by_category.dart';
import '../../features/product/domain/usecases/get_subcategories.dart';
import '../../features/product/domain/usecases/search_products.dart';
import '../../features/product/presentation/blocs/product_bloc.dart';

void registerProductDependencies(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(client: sl()),
  );

  // Repositories
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases (Only product-specific use cases)
  sl.registerLazySingleton(() => GetFeaturedProducts(sl()));
  sl.registerLazySingleton(() => GetProductsByCategory(sl()));
  sl.registerLazySingleton(() => SearchProducts(sl()));
  sl.registerLazySingleton(() => GetProductById(sl()));

  // BLoC
  sl.registerFactory(
    () => ProductBloc(
      getCategories: sl(), // Resolves successfully from Category registrations
      getSubcategories:
          sl(), // Resolves successfully from Category registrations
      getFeaturedProducts: sl(),
      getProductsByCategory: sl(),
      searchProducts: sl(),
      getProductById: sl(),
    ),
  );
}
