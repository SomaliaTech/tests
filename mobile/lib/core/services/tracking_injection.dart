// lib/core/services/tracking_injection.dart
import 'package:get_it/get_it.dart';
import 'package:mobile/features/tracking/data/datasources/tracking_remote_datasource.dart';
import 'package:mobile/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:mobile/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mobile/features/tracking/domain/usecases/get_tracking_info.dart';
import 'package:mobile/features/tracking/presentation/bloc/tracking_bloc.dart';

void trakingRegisterProductDependencies(GetIt sl) {
  // Fixed function name
  print('📦 Registering Tracking Dependencies...');

  // Data Sources
  if (!sl.isRegistered<TrackingRemoteDataSource>()) {
    sl.registerLazySingleton<TrackingRemoteDataSource>(
      () => TrackingRemoteDataSourceImpl(client: sl()),
    );
  }

  // Repositories
  // if (!sl.isRegistered<TrackingRepository>()) {
  //   sl.registerLazySingleton<TrackingRepository>(
  //     () => TrackingRepositoryImpl(remoteDataSource: sl()),
  //   );
  // }

  // Use Cases
  if (!sl.isRegistered<GetTrackingInfo>()) {
    sl.registerLazySingleton(() => GetTrackingInfo(sl()));
  }
  // if (!sl.isRegistered<UpdateTrackingStatus>()) {
  //   sl.registerLazySingleton(() => UpdateTrackingStatus(sl()));
  // }

  // BLoC
  if (!sl.isRegistered<TrackingBloc>()) {
    sl.registerFactory(
      () => TrackingBloc(
        getTrackingInfo: sl(),
        // updateTrackingStatus: sl(),
      ),
    );
  }

  print('✅ Tracking Dependencies Registered');
}
