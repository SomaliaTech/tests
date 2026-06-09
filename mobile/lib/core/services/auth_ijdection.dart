import 'package:get_it/get_it.dart';
import 'package:mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/usecases/check_auth_status.dart';
import 'package:mobile/features/auth/domain/usecases/get_current_user.dart';
import 'package:mobile/features/auth/domain/usecases/logout.dart';
import 'package:mobile/features/auth/domain/usecases/complete_profile.dart';
import 'package:mobile/features/auth/domain/usecases/send_otp.dart';
import 'package:mobile/features/auth/domain/usecases/upload_profile_image.dart';
import 'package:mobile/features/auth/domain/usecases/verify_otp.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';

void authRegisterDependencies(GetIt sl) {
  // REMOVED StorageService registration from here - it's already registered in injection_container.dart

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), storageService: sl()),
  );

  sl.registerLazySingleton(() => SendOtp(sl()));
  sl.registerLazySingleton(() => VerifyOtp(sl()));
  sl.registerLazySingleton(() => CompleteProfile(sl()));
  sl.registerLazySingleton(() => UploadProfileImage(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => CheckAuthStatus(sl()));
  sl.registerLazySingleton(() => Logout(sl()));

  sl.registerFactory(
    () => AuthBloc(
      sendOtp: sl(),
      verifyOtp: sl(),
      completeProfile: sl(),
      uploadProfileImage: sl(),
      getCurrentUser: sl(),
      checkAuthStatus: sl(),
      logout: sl(),
    ),
  );
}
