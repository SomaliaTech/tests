import 'package:get_it/get_it.dart';
import 'package:mobile/features/admin/data/datasources/analytics_remote_data_source.dart';
import 'package:mobile/features/admin/data/repositories/analytics_repository_impl.dart';
import 'package:mobile/features/admin/domain/repositories/analytics_repository.dart';
import 'package:mobile/features/admin/presentation/bloc/analytics/analytics_bloc.dart';

void registerAnalyticsDependencies(GetIt sl) {
  // Data sources
  sl.registerLazySingleton<AnalyticsRemoteDataSource>(
    () => AnalyticsRemoteDataSourceImpl(client: sl(), storageService: sl()),
  );

  // Repository
  sl.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(remoteDataSource: sl()),
  );

  // BLoC
  sl.registerFactory(() => AnalyticsBloc(repository: sl()));
}
