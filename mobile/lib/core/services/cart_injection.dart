import 'package:get_it/get_it.dart';
// 🚨 REMOVED: cart_remote_datasource.dart import
import 'package:mobile/features/cart/data/datasources/cart_local_datasource.dart';
import 'package:mobile/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:mobile/features/cart/domain/repositories/cart_repository.dart';
import 'package:mobile/features/cart/domain/usecases/add_to_cart.dart';
import 'package:mobile/features/cart/domain/usecases/clear_cart.dart';
import 'package:mobile/features/cart/domain/usecases/get_cart_items.dart';
import 'package:mobile/features/cart/domain/usecases/remove_item.dart';
import 'package:mobile/features/cart/domain/usecases/update_quantity.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_bloc.dart';

void cartRegisterDependencies(GetIt sl) {
  // 1. Data Sources (ONLY LOCAL NOW)
  sl.registerLazySingleton<CartLocalDataSource>(
    () => CartLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // 2. Repositories
  // 🚨 FIXED: Removed remoteDataSource and storageService
  sl.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(localDataSource: sl()),
  );

  // 3. Use Cases
  sl.registerLazySingleton(() => GetCartItems(sl()));
  sl.registerLazySingleton(() => AddToCart(sl()));
  sl.registerLazySingleton(() => UpdateQuantity(sl()));
  sl.registerLazySingleton(() => RemoveItem(sl()));
  sl.registerLazySingleton(() => ClearCart(sl()));

  // 4. BLoC
  sl.registerFactory(
    () => CartBloc(
      getCartItems: sl(),
      addToCart: sl(),
      updateQuantity: sl(),
      removeItem: sl(),
      clearCart: sl(),
    ),
  );
}
