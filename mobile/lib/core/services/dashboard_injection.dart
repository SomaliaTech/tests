import 'package:get_it/get_it.dart';
import 'package:mobile/features/admin/data/datasources/dashboard_remote_data_source.dart';
import 'package:mobile/features/admin/data/repositories/dashboard_repository_impl.dart';
import 'package:mobile/features/admin/domain/repositories/dashboard_repository.dart';
import 'package:mobile/features/admin/presentation/bloc/dashborad/dashboard_bloc.dart';

void registerDashboardDependencies(GetIt sl) {
  // Data Source
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(client: sl(), storageService: sl()),
  );

  // Repository
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(remoteDataSource: sl()),
  );

  // BLoC
  sl.registerFactory(() => DashboardBloc(repository: sl()));
}
