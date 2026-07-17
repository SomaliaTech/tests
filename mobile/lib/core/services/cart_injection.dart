import 'package:get_it/get_it.dart';
import '../../features/cart/data/datasources/cart_local_datasource.dart';
import '../../features/cart/data/repositories/cart_repository_impl.dart';
import '../../features/cart/domain/repositories/cart_repository.dart';
import '../../features/cart/domain/usecases/add_to_cart.dart'; // ✅ Add this
import '../../features/cart/domain/usecases/get_cart_items.dart';
import '../../features/cart/domain/usecases/update_quantity.dart';
import '../../features/cart/domain/usecases/remove_item.dart';
import '../../features/cart/domain/usecases/clear_cart.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';

void registerCartDependencies(GetIt sl) {
  // Data Source
  sl.registerLazySingleton<CartLocalDataSource>(
    () => CartLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Repository
  sl.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(localDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetCartItems(sl()));
  sl.registerLazySingleton(() => AddToCart(sl())); // ✅ Add this
  sl.registerLazySingleton(() => UpdateQuantity(sl()));
  sl.registerLazySingleton(() => RemoveItem(sl()));
  sl.registerLazySingleton(() => ClearCart(sl()));

  // Bloc
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
