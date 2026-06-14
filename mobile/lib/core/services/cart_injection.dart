import 'package:get_it/get_it.dart';
import 'package:mobile/features/cart/data/datasources/cart_remote_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/cart/data/datasources/cart_local_datasource.dart';
import '../../features/cart/data/repositories/cart_repository_impl.dart';
import '../../features/cart/domain/repositories/cart_repository.dart';
import '../../features/cart/domain/usecases/add_to_cart.dart';
import '../../features/cart/domain/usecases/clear_cart.dart';
import '../../features/cart/domain/usecases/get_cart_items.dart';
import '../../features/cart/domain/usecases/remove_item.dart';
import '../../features/cart/domain/usecases/update_quantity.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';

void cartRegisterDependencies(GetIt sl) async {
  // Data Sources
  sl.registerLazySingleton<CartRemoteDataSource>(
    () => CartRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<CartLocalDataSource>(
    () => CartLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Repositories
  sl.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      storageService: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetCartItems(sl()));
  sl.registerLazySingleton(() => AddToCart(sl()));
  sl.registerLazySingleton(() => UpdateQuantity(sl()));
  sl.registerLazySingleton(() => RemoveItem(sl()));
  sl.registerLazySingleton(() => ClearCart(sl()));

  // BLoC
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
