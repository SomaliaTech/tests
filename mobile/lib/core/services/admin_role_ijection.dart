import 'package:get_it/get_it.dart';
import 'package:mobile/features/admin/data/datasources/admin_role_remote_data_source.dart';
import 'package:mobile/features/admin/data/repositories/admin_role_repository_impl.dart';
import 'package:mobile/features/admin/domain/repositories/admin_role_repository.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_role/admin_role_bloc.dart';

void registerAdminRoleDependencies(GetIt sl) {
  sl.registerLazySingleton<AdminRoleRemoteDataSource>(
    () => AdminRoleRemoteDataSourceImpl(client: sl(), storageService: sl()),
  );
  sl.registerLazySingleton<AdminRoleRepository>(
    () => AdminRoleRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory<AdminRoleBloc>(() => AdminRoleBloc(repository: sl()));
}
