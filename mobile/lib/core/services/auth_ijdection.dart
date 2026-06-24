// lib/core/services/auth_injection.dart
import 'package:get_it/get_it.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/usecases/check_auth_status.dart';
import 'package:mobile/features/auth/domain/usecases/complete_profile.dart';
import 'package:mobile/features/auth/domain/usecases/get_current_user.dart';
import 'package:mobile/features/auth/domain/usecases/logout.dart';
import 'package:mobile/features/auth/domain/usecases/send_otp.dart';
import 'package:mobile/features/auth/domain/usecases/upload_profile_image.dart';
import 'package:mobile/features/auth/domain/usecases/verify_otp.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';

void authRegisterDependencies(GetIt sl) {
  print('📦 Registering Auth Dependencies...');

  // Data Sources
  if (!sl.isRegistered<AuthRemoteDataSource>()) {
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(client: sl()),
    );
  }

  // Repositories
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: sl(), storageService: sl()),
    );
  }

  // Use Cases
  if (!sl.isRegistered<SendOtp>()) {
    sl.registerLazySingleton(() => SendOtp(sl()));
  }
  if (!sl.isRegistered<VerifyOtp>()) {
    sl.registerLazySingleton(() => VerifyOtp(sl()));
  }
  if (!sl.isRegistered<CompleteProfile>()) {
    sl.registerLazySingleton(() => CompleteProfile(sl()));
  }
  if (!sl.isRegistered<UploadProfileImage>()) {
    sl.registerLazySingleton(() => UploadProfileImage(sl()));
  }
  if (!sl.isRegistered<GetCurrentUser>()) {
    sl.registerLazySingleton(() => GetCurrentUser(sl()));
  }
  if (!sl.isRegistered<CheckAuthStatus>()) {
    sl.registerLazySingleton(() => CheckAuthStatus(sl()));
  }
  if (!sl.isRegistered<Logout>()) {
    sl.registerLazySingleton(() => Logout(sl()));
  }

  // BLoC
  if (!sl.isRegistered<AuthBloc>()) {
    sl.registerFactory(
      () => AuthBloc(
        sendOtp: sl(),
        verifyOtp: sl(),
        completeProfile: sl(),
        uploadProfileImage: sl(),
        getCurrentUser: sl(),
        checkAuthStatus: sl(),
        logout: sl(),
        storageService: sl(),
        chatSocketService: sl<ChatSocketService>(), // 🚨 ADD THIS LINE
      ),
    );
  }

  print('✅ Auth Dependencies Registered');
}
