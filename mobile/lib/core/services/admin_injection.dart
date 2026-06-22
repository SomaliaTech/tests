import 'package:get_it/get_it.dart';
import 'package:mobile/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:mobile/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_bloc.dart';

void registerAdminDependencies(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminRemoteDataSourceImpl(client: sl(), storageService: sl()),
  );

  // Repository
  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(remoteDataSource: sl()),
  );

  // BLoC
  sl.registerFactory(() => AdminBloc(repository: sl()));
}
