import 'package:get_it/get_it.dart';
import 'package:mobile/features/tracking/data/datasources/tracking_remote_datasource.dart';
import 'package:mobile/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:mobile/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mobile/features/tracking/domain/usecases/get_tracking_info.dart';
import 'package:mobile/features/tracking/presentation/bloc/tracking_bloc.dart';

void TrakingregisterProductDependencies(GetIt sl) {
  sl.registerLazySingleton<TrackingRemoteDataSource>(
    () => TrackingRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<TrackingRepository>(
    () => TrackingRepositoryImpl(remoteDataSource: sl(), storageService: sl()),
  );
  sl.registerLazySingleton(() => GetTrackingInfo(sl()));
  sl.registerFactory(() => TrackingBloc(getTrackingInfo: sl()));
}
