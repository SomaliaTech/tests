import 'package:get_it/get_it.dart';
import '../../features/wishlist/data/datasources/wishlist_local_datasource.dart';
import '../../features/wishlist/data/repositories/wishlist_repository_impl.dart';
import '../../features/wishlist/domain/repository/wishlist_repository.dart';
import '../../features/wishlist/domain/usecases/add_to_wishlist.dart';
import '../../features/wishlist/domain/usecases/clear_wishlist.dart';
import '../../features/wishlist/domain/usecases/get_wishlist_items.dart';
import '../../features/wishlist/domain/usecases/is_in_wishlist.dart';
import '../../features/wishlist/domain/usecases/remove_from_wishlist.dart';
import '../../features/wishlist/presentation/bloc/wishlist_bloc.dart';

void registerWishlistDependencies(GetIt sl) {
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
}
