import 'package:get_it/get_it.dart';
import 'package:mobile/features/admin/data/datasources/admin_category_remote_data_source.dart';
import 'package:mobile/features/admin/data/datasources/admin_color_size_remote_data_source.dart';
import 'package:mobile/features/admin/data/datasources/admin_market_remote_data_source.dart';
import 'package:mobile/features/admin/data/datasources/admin_product_remote_data_source.dart';
import 'package:mobile/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:mobile/features/admin/data/datasources/admin_revenue_remote_data_source.dart';
import 'package:mobile/features/admin/data/datasources/admin_user_remote_data_source.dart';
import 'package:mobile/features/admin/data/repositories/admin_category_repository_impl.dart';
import 'package:mobile/features/admin/data/repositories/admin_color_size_repository_impl.dart';
import 'package:mobile/features/admin/data/repositories/admin_market_repository_impl.dart';
import 'package:mobile/features/admin/data/repositories/admin_product_repository_impl.dart';
import 'package:mobile/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:mobile/features/admin/data/repositories/admin_revenue_repository_impl.dart';
import 'package:mobile/features/admin/data/repositories/admin_user_repository_impl.dart';
import 'package:mobile/features/admin/domain/repositories/admin_category_repository.dart';
import 'package:mobile/features/admin/domain/repositories/admin_color_size_repository.dart';
import 'package:mobile/features/admin/domain/repositories/admin_market_repository.dart';
import 'package:mobile/features/admin/domain/repositories/admin_product_repository.dart';
import 'package:mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:mobile/features/admin/domain/repositories/admin_revenue_repository.dart';
import 'package:mobile/features/admin/domain/repositories/admin_user_repository.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_category/admin_category_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_color_size/admin_color_size_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_market/admin_market_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/revenue/revenue_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_bloc.dart';

void registerAdminDependencies(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminRemoteDataSourceImpl(client: sl(), storageService: sl()),
  );
  sl.registerLazySingleton<AdminUserRemoteDataSource>(
    () => AdminUserRemoteDataSourceImpl(client: sl(), storageService: sl()),
  );
  sl.registerLazySingleton<AdminRevenueRemoteDataSource>(
    () => AdminRevenueRemoteDataSourceImpl(client: sl(), storageService: sl()),
  );
  sl.registerLazySingleton<AdminProductRemoteDataSource>(
    () => AdminProductRemoteDataSourceImpl(client: sl(), storageService: sl()),
  );
  // ✅ ADD THIS
  sl.registerLazySingleton<AdminCategoryRemoteDataSource>(
    () => AdminCategoryRemoteDataSourceImpl(client: sl(), storageService: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AdminUserRepository>(
    () => AdminUserRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AdminRevenueRepository>(
    () => AdminRevenueRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AdminProductRepository>(
    () => AdminProductRepositoryImpl(remoteDataSource: sl()),
  );
  // ✅ ADD THIS
  sl.registerLazySingleton<AdminCategoryRepository>(
    () => AdminCategoryRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<AdminColorSizeRemoteDataSource>(
    () =>
        AdminColorSizeRemoteDataSourceImpl(client: sl(), storageService: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AdminColorSizeRepository>(
    () => AdminColorSizeRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<AdminMarketRemoteDataSource>(
    () => AdminMarketRemoteDataSourceImpl(client: sl(), storageService: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AdminMarketRepository>(
    () => AdminMarketRepositoryImpl(remoteDataSource: sl()),
  );

  // BLoCs
  sl.registerFactory(() => AdminMarketBloc(repository: sl()));

  // BLoCs
  sl.registerFactory(() => AdminColorSizeBloc(repository: sl()));
  // BLoCs
  sl.registerFactory(() => AdminBloc(repository: sl()));
  sl.registerFactory(() => UserBloc(repository: sl()));
  sl.registerFactory(() => RevenueBloc(repository: sl()));
  sl.registerFactory(() => AdminProductBloc(repository: sl()));
  // ✅ ADD THIS
  sl.registerFactory(() => AdminCategoryBloc(repository: sl()));
}
