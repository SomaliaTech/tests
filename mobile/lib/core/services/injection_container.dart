import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

// Core imports
import '../network/network_info.dart'; // Adjust this path to your NetworkInfo file

// Feature Product imports
import '../../features/product/data/datasources/product_remote_datasource.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';
import '../../features/product/domain/repositories/product_repository.dart';
import '../../features/product/domain/usecases/get_categories.dart';
import '../../features/product/domain/usecases/get_featured_products.dart';
import '../../features/product/domain/usecases/get_products_by_category.dart';
import '../../features/product/domain/usecases/search_products.dart';
import '../../features/product/presentation/blocs/product_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ==========================================
  // 🌐 CORE & EXTERNAL DEPENDENCIES
  // ==========================================
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => InternetConnection());

  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(internetConnection: sl()),
  );

  // ==========================================
  // 📦 FEATURE - PRODUCT
  // ==========================================

  // 1. Data Sources
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(client: sl()),
  );

  // 2. Repositories
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(remoteDataSource: sl()),
  );

  // 3. Use Cases
  sl.registerLazySingleton(() => GetCategories(sl()));
  sl.registerLazySingleton(() => GetFeaturedProducts(sl()));
  sl.registerLazySingleton(() => GetProductsByCategory(sl()));
  sl.registerLazySingleton(() => SearchProducts(sl()));

  // 4. Blocs / State Management (Always register as Factory so they reset when closed)
  sl.registerFactory(
    () => ProductBloc(
      getCategories: sl(),
      getFeaturedProducts: sl(),
      getProductsByCategory: sl(),
      searchProducts: sl(),
    ),
  );
}
