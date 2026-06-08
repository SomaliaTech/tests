import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mobile/core/network/network_info.dart';
import 'package:mobile/features/product/data/datasources/product_remote_datasource.dart';
import 'package:mobile/features/product/data/repositories/product_repository_impl.dart';
import 'package:mobile/features/product/domain/repositories/product_repository.dart';
import 'package:mobile/features/product/domain/usecases/get_categories.dart';
import 'package:mobile/features/product/domain/usecases/get_featured_products.dart';
import 'package:mobile/features/product/domain/usecases/get_product_by_id.dart';
import 'package:mobile/features/product/domain/usecases/get_products_by_category.dart';
import 'package:mobile/features/product/domain/usecases/get_subcategories.dart';
import 'package:mobile/features/product/domain/usecases/search_products.dart';
import 'package:mobile/features/product/presentation/blocs/product_bloc.dart';
import 'package:mobile/features/wishlist/data/datasources/wishlist_local_datasource.dart';
import 'package:mobile/features/wishlist/data/repositories/wishlist_repository_impl.dart';
import 'package:mobile/features/wishlist/domain/repository/wishlist_repository.dart';
import 'package:mobile/features/wishlist/domain/usecases/add_to_wishlist.dart';
import 'package:mobile/features/wishlist/domain/usecases/clear_wishlist.dart';
import 'package:mobile/features/wishlist/domain/usecases/get_wishlist_items.dart';
import 'package:mobile/features/wishlist/domain/usecases/is_in_wishlist.dart';
import 'package:mobile/features/wishlist/domain/usecases/remove_from_wishlist.dart';
import 'package:mobile/features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ==========================================
  // 🌐 CORE & EXTERNAL DEPENDENCIES

  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => InternetConnection());

  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(internetConnection: sl()),
  );

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // ==========================================
  // 📦 FEATURE - WISHLIST
  // ==========================================

  // Data Sources
  sl.registerLazySingleton<WishlistLocalDataSource>(
    () => WishlistLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Repositories
  sl.registerLazySingleton<WishlistRepository>(
    () => WishlistRepositoryImpl(localDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetWishlistItems(sl()));
  sl.registerLazySingleton(() => AddToWishlist(sl()));
  sl.registerLazySingleton(() => RemoveFromWishlist(sl()));
  sl.registerLazySingleton(() => ClearWishlist(sl()));
  sl.registerLazySingleton(() => IsInWishlist(sl()));

  // BLoC
  sl.registerFactory(
    () => WishlistBloc(
      getWishlistItems: sl(),
      addToWishlist: sl(),
      removeFromWishlist: sl(),
      clearWishlist: sl(),
      isInWishlist: sl(),
    ),
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
  sl.registerLazySingleton(() => GetSubcategories(sl()));
  sl.registerLazySingleton(() => GetFeaturedProducts(sl()));
  sl.registerLazySingleton(() => GetProductsByCategory(sl()));
  sl.registerLazySingleton(() => SearchProducts(sl()));
  sl.registerLazySingleton(() => GetProductById(sl()));

  // 4. Blocs / State Management
  sl.registerFactory(
    () => ProductBloc(
      getCategories: sl(),
      getSubcategories: sl(),
      getFeaturedProducts: sl(),
      getProductsByCategory: sl(),
      searchProducts: sl(),
      getProductById: sl(),
    ),
  );
}
