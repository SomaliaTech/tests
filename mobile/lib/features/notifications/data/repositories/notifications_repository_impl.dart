import 'dart:async';
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/services/server_status_service.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_local_datasource.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../domain/entities/notification.dart';
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
        return const Right([]);
      }

      final notifications = await remoteDataSource.getNotifications(token);

      // ✅ Server is up!
      ServerStatusService().markServerUp();

      return Right(notifications);
    } on SocketException {
      // ✅ Server is down
      ServerStatusService().markServerDown();
      return const Right([]); // Return empty silently
    } catch (e) {
      if (e.toString().contains('Connection refused')) {
        ServerStatusService().markServerDown();
        return const Right([]); // Return empty silently
      }
      debugPrint('⚠️ Failed to fetch notifications: $e');
      return const Right([]); // Return empty silently for background fetches
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String id) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return Left(Failure('Please login to continue'));
      }

      await remoteDataSource.markAsRead(token, id);
      return const Right(null);
    } on SocketException {
      return Left(Failure('No internet connection'));
    } catch (e) {
      return Left(Failure(_parseError(e)));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return Left(Failure('Please login to continue'));
      }

      await remoteDataSource.markAllAsRead(token);
      return const Right(null);
    } on SocketException {
      return Left(Failure('No internet connection'));
    } catch (e) {
      return Left(Failure(_parseError(e)));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String id) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return Left(Failure('Please login to continue'));
      }

      await remoteDataSource.deleteNotification(token, id);
      return const Right(null);
    } on SocketException {
      return Left(Failure('No internet connection'));
    } catch (e) {
      return Left(Failure(_parseError(e)));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllNotifications() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return Left(Failure('Please login to continue'));
      }

      await remoteDataSource.clearAllNotifications(token);
      return const Right(null);
    } on SocketException {
      return Left(Failure('No internet connection'));
    } catch (e) {
      return Left(Failure(_parseError(e)));
    }
  }

  /// Clean up error message for user display
  String _parseError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('connection refused') ||
        errorStr.contains('network')) {
      return 'Unable to connect to server. Please try again.';
    }
    if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
      return 'Session expired. Please login again.';
    }

    // Clean up technical error messages
    return errorStr
        .replaceAll('exception: ', '')
        .replaceAll('error: ', '')
        .replaceAll('failed: ', '');
  }
}

// ✅ Helper function for debug printing
void debugPrint(String message) {
  print(message);
}
