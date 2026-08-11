// lib/core/services/product_injection.dart
import 'package:get_it/get_it.dart';
import 'package:mobile/features/product/data/datasources/local/category_local_datasource.dart';
import 'package:mobile/features/product/data/datasources/local/product_local_datasource.dart';
import 'package:mobile/features/product/data/datasources/product_remote_datasource.dart';
import 'package:mobile/features/product/data/repositories/product_repository_impl.dart';
import 'package:mobile/features/product/domain/repositories/product_repository.dart';
import 'package:mobile/features/product/domain/usecases/get_featured_products.dart';
import 'package:mobile/features/product/domain/usecases/get_latest_products.dart'; // ✅ Added
import 'package:mobile/features/product/domain/usecases/get_product_by_id.dart';
import 'package:mobile/features/product/domain/usecases/get_products_by_category.dart';
import 'package:mobile/features/product/domain/usecases/search_products.dart';
import 'package:mobile/features/product/presentation/blocs/product_bloc.dart';

void registerProductDependencies(GetIt sl) {
  // Local Data Sources
  // ✅ Only register ProductLocalDataSource here
  if (!sl.isRegistered<ProductLocalDataSource>()) {
    sl.registerLazySingleton<ProductLocalDataSource>(
      () => ProductLocalDataSourceImpl(),
    );
  }

  // ✅ CategoryLocalDataSource is already registered in category_injection.dart
  // DO NOT register it again here

  // Remote Data Source
  if (!sl.isRegistered<ProductRemoteDataSource>()) {
    sl.registerLazySingleton<ProductRemoteDataSource>(
      () => ProductRemoteDataSourceImpl(client: sl()),
    );
  }

  // Repository with ALL data sources
  if (!sl.isRegistered<ProductRepository>()) {
    sl.registerLazySingleton<ProductRepository>(
      () => ProductRepositoryImpl(
        remoteDataSource: sl<ProductRemoteDataSource>(),
        localDataSource: sl<ProductLocalDataSource>(),
        categoryLocalDataSource: sl<CategoryLocalDataSource>(),
      ),
    );
  }

  // Use Cases
  if (!sl.isRegistered<GetFeaturedProducts>()) {
    sl.registerLazySingleton(() => GetFeaturedProducts(sl()));
  }
  if (!sl.isRegistered<GetLatestProducts>()) {
    sl.registerLazySingleton(() => GetLatestProducts(sl())); // ✅ Added
  }
  if (!sl.isRegistered<GetProductsByCategory>()) {
    sl.registerLazySingleton(() => GetProductsByCategory(sl()));
  }
  if (!sl.isRegistered<SearchProducts>()) {
    sl.registerLazySingleton(() => SearchProducts(sl()));
  }
  if (!sl.isRegistered<GetProductById>()) {
    sl.registerLazySingleton(() => GetProductById(sl()));
  }

  // BLoC
  if (!sl.isRegistered<ProductBloc>()) {
    sl.registerFactory(
      () => ProductBloc(
        getCategories: sl(),
        getSubcategories: sl(),
        getFeaturedProducts: sl(),
        getLatestProducts: sl(),
        getProductsByCategory: sl(),
        searchProducts: sl(),
        getProductById: sl(),
      ),
    );
  }
}
