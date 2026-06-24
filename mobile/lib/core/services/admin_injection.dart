import 'package:get_it/get_it.dart';
import 'package:mobile/features/admin/data/datasources/admin_product_remote_data_source.dart';
import 'package:mobile/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:mobile/features/admin/data/datasources/admin_revenue_remote_data_source.dart';
import 'package:mobile/features/admin/data/datasources/admin_user_remote_data_source.dart';
import 'package:mobile/features/admin/data/repositories/admin_product_repository_impl.dart';
import 'package:mobile/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:mobile/features/admin/data/repositories/admin_revenue_repository_impl.dart';
import 'package:mobile/features/admin/data/repositories/admin_user_repository_impl.dart';
import 'package:mobile/features/admin/domain/repositories/admin_product_repository.dart';
import 'package:mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:mobile/features/admin/domain/repositories/admin_revenue_repository.dart';
import 'package:mobile/features/admin/domain/repositories/admin_user_repository.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_bloc.dart';
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

  // BLoCs
  sl.registerFactory(() => AdminBloc(repository: sl()));
  sl.registerFactory(() => UserBloc(repository: sl()));
  sl.registerFactory(() => RevenueBloc(repository: sl()));
  sl.registerFactory(() => AdminProductBloc(repository: sl()));
}
