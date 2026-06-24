import 'package:fpdart/fpdart.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_local_datasource.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../domain/entities/notification.dart';

// 🚨 IMPORTANT: Do NOT import core/error/failures.dart here.
// We must use the Failure class from the domain repository!
import '../../domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource remoteDataSource;
  final StorageService storageService;

  NotificationsRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  Future<String?> _getToken() async {
    return await storageService.getAuthToken();
  }

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        // 🚨 Use the domain's Failure class exactly as your original code did
        return Left(Failure('Authentication token is empty'));
      }

      final notifications = await remoteDataSource.getNotifications(token);
      return Right(notifications);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String id) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return Left(Failure('Authentication token is empty'));
      }

      await remoteDataSource.markAsRead(token, id);
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return Left(Failure('Authentication token is empty'));
      }

      await remoteDataSource.markAllAsRead(token);
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String id) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return Left(Failure('Authentication token is empty'));
      }

      await remoteDataSource.deleteNotification(token, id);
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllNotifications() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return Left(Failure('Authentication token is empty'));
      }

      await remoteDataSource.clearAllNotifications(token);
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
