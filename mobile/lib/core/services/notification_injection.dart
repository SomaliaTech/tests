import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_local_datasource.dart';
import 'package:mobile/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:mobile/features/notifications/domain/usecases/clear_all_notifications.dart';
import 'package:mobile/features/notifications/domain/usecases/delete_notification.dart';
import 'package:mobile/features/notifications/domain/usecases/get_notifications.dart';
import 'package:mobile/features/notifications/domain/usecases/mark_all_as_read.dart';
import 'package:mobile/features/notifications/domain/usecases/mark_as_read.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_bloc.dart';

final GetIt sl = GetIt.instance;

void registerNotificationDependencies() {
  print('📦 Registering Notification Dependencies...');

  // Data Sources
  if (!sl.isRegistered<NotificationsRemoteDataSource>()) {
    sl.registerLazySingleton<NotificationsRemoteDataSource>(
      () => NotificationsRemoteDataSource(client: sl<http.Client>()),
    );
  }

  // Repositories
  if (!sl.isRegistered<NotificationsRepository>()) {
    sl.registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(
        remoteDataSource: sl<NotificationsRemoteDataSource>(),
        storageService: sl<StorageService>(), // ✅ FIXED: Use StorageService
      ),
    );
  }

  // Use Cases
  if (!sl.isRegistered<GetNotifications>()) {
    sl.registerLazySingleton(
      () => GetNotifications(sl<NotificationsRepository>()),
    );
  }
  if (!sl.isRegistered<MarkAsRead>()) {
    sl.registerLazySingleton(() => MarkAsRead(sl<NotificationsRepository>()));
  }
  if (!sl.isRegistered<MarkAllAsRead>()) {
    sl.registerLazySingleton(
      () => MarkAllAsRead(sl<NotificationsRepository>()),
    );
  }
  if (!sl.isRegistered<DeleteNotification>()) {
    sl.registerLazySingleton(
      () => DeleteNotification(sl<NotificationsRepository>()),
    );
  }
  if (!sl.isRegistered<ClearAllNotifications>()) {
    sl.registerLazySingleton(
      () => ClearAllNotifications(sl<NotificationsRepository>()),
    );
  }

  // BLoC
  if (!sl.isRegistered<NotificationsBloc>()) {
    sl.registerFactory(
      () => NotificationsBloc(
        getNotifications: sl<GetNotifications>(),
        markAsRead: sl<MarkAsRead>(),
        markAllAsRead: sl<MarkAllAsRead>(),
        deleteNotification: sl<DeleteNotification>(),
        clearAllNotifications: sl<ClearAllNotifications>(),
      ),
    );
  }

  print('✅ Notification Dependencies Registered');
}

NotificationsBloc getNotificationBloc() {
  return sl<NotificationsBloc>();
}
