// lib/core/services/banner_injection.dart

import 'package:get_it/get_it.dart';
import 'package:mobile/features/admin/presentation/bloc/banner/admin_banner_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/banner/banner_bloc.dart';
import '../../features/product/data/datasources/banner_remote_data_source.dart';
import '../../features/product/data/datasources/local/banner_local_data_source.dart';
import '../../features/product/data/repositories/banner_repository_impl.dart';
import '../../features/product/domain/repositories/banner_repository.dart';
import '../../features/product/domain/usecases/banner/get_active_banners.dart';
import '../../features/product/domain/usecases/banner/get_all_banners.dart';
import '../../features/product/domain/usecases/banner/create_banner.dart';
import '../../features/product/domain/usecases/banner/update_banner.dart';
import '../../features/product/domain/usecases/banner/delete_banner.dart';
import '../../features/product/domain/usecases/banner/toggle_banner_status.dart';
import 'connectivity_service.dart'; // ✅ ADD THIS IMPORT

void registerBannerDependencies(GetIt sl) {
  print('📦 Registering Banner Dependencies...');

  // Data Sources
  sl.registerLazySingleton<BannerRemoteDataSource>(
    () => BannerRemoteDataSourceImpl(client: sl(), storageService: sl()),
  );
  print('✅ BannerRemoteDataSource registered');

  sl.registerLazySingleton<BannerLocalDataSource>(
    () => BannerLocalDataSourceImpl(),
  );
  print('✅ BannerLocalDataSource registered');

  // Repository
  sl.registerLazySingleton<BannerRepository>(
    () => BannerRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  print('✅ BannerRepository registered');

  // Use Cases
  sl.registerLazySingleton(() => GetActiveBanners(sl()));
  sl.registerLazySingleton(() => GetAllBanners(sl()));
  sl.registerLazySingleton(() => CreateBanner(sl()));
  sl.registerLazySingleton(() => UpdateBanner(sl()));
  sl.registerLazySingleton(() => DeleteBanner(sl()));
  sl.registerLazySingleton(() => ToggleBannerStatus(sl()));
  print('✅ Banner Use Cases registered');

  // BLoCs - ✅ Get ConnectivityService from GetIt
  sl.registerFactory(
    () => BannerBloc(
      getActiveBanners: sl(),
      connectivityService:
          sl<ConnectivityService>(), // ✅ Explicitly get from GetIt
    ),
  );
  sl.registerFactory(
    () => AdminBannerBloc(
      getAllBanners: sl(),
      createBanner: sl(),
      updateBanner: sl(),
      deleteBanner: sl(),
      toggleBannerStatus: sl(),
    ),
  );
  print('✅ Banner BLoCs registered');
}
