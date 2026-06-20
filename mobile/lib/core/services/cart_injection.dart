// lib/core/services/cart_injection.dart
import 'package:get_it/get_it.dart';
import 'package:mobile/features/cart/data/datasources/cart_remote_datasource.dart';
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
  // Removed async
  print('📦 Registering Cart Dependencies...');

  // Data Sources
  if (!sl.isRegistered<CartRemoteDataSource>()) {
    sl.registerLazySingleton<CartRemoteDataSource>(
      () => CartRemoteDataSourceImpl(client: sl()),
    );
  }

  if (!sl.isRegistered<CartLocalDataSource>()) {
    sl.registerLazySingleton<CartLocalDataSource>(
      () => CartLocalDataSourceImpl(sharedPreferences: sl()),
    );
  }

  // Repositories
  if (!sl.isRegistered<CartRepository>()) {
    sl.registerLazySingleton<CartRepository>(
      () => CartRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        storageService: sl(),
      ),
    );
  }

  // Use Cases
  if (!sl.isRegistered<GetCartItems>()) {
    sl.registerLazySingleton(() => GetCartItems(sl()));
  }
  if (!sl.isRegistered<AddToCart>()) {
    sl.registerLazySingleton(() => AddToCart(sl()));
  }
  if (!sl.isRegistered<UpdateQuantity>()) {
    sl.registerLazySingleton(() => UpdateQuantity(sl()));
  }
  if (!sl.isRegistered<RemoveItem>()) {
    sl.registerLazySingleton(() => RemoveItem(sl()));
  }
  if (!sl.isRegistered<ClearCart>()) {
    sl.registerLazySingleton(() => ClearCart(sl()));
  }

  // BLoC
  if (!sl.isRegistered<CartBloc>()) {
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

  print('✅ Cart Dependencies Registered');
}
