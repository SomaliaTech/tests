// lib/core/services/profile_injection.dart
import 'package:get_it/get_it.dart';
import 'package:mobile/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:mobile/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:mobile/features/profile/domain/usecases/delete_account.dart';
import 'package:mobile/features/profile/domain/usecases/get_profile.dart';
import 'package:mobile/features/profile/domain/usecases/update_profile.dart';
import 'package:mobile/features/profile/domain/usecases/upload_profile_image.dart';
import 'package:mobile/features/profile/presentation/bloc/profile_bloc.dart';

void registerProfileDependencies(GetIt sl) {
  print('📦 Registering Profile Dependencies...');

  // Data Sources
  if (!sl.isRegistered<ProfileRemoteDataSource>()) {
    sl.registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSourceImpl(client: sl()),
    );
  }

  // Repositories
  if (!sl.isRegistered<ProfileRepository>()) {
    sl.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(remoteDataSource: sl(), storageService: sl()),
    );
  }

  // Use Cases
  if (!sl.isRegistered<GetProfile>()) {
    sl.registerLazySingleton(() => GetProfile(sl()));
  }
  if (!sl.isRegistered<UpdateProfile>()) {
    sl.registerLazySingleton(() => UpdateProfile(sl()));
  }
  if (!sl.isRegistered<UploadProfileImage>()) {
    sl.registerLazySingleton(() => UploadProfileImage(sl()));
  }
  if (!sl.isRegistered<DeleteAccount>()) {
    sl.registerLazySingleton(() => DeleteAccount(sl()));
  }

  // BLoC
  if (!sl.isRegistered<ProfileBloc>()) {
    sl.registerFactory(
      () => ProfileBloc(
        getProfile: sl(),
        updateProfile: sl(),
        uploadProfileImage: sl(),
        deleteAccount: sl(),
      ),
    );
  }

  print('✅ Profile Dependencies Registered');
}
