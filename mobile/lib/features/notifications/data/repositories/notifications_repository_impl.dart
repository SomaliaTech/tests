import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/services/server_status_service.dart';
import 'package:mobile/features/notifications/data/datasources/local/notifications_local_datasource.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_datasource.dart';

import '../../../../core/services/storage/storage_service.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource remoteDataSource;
  final NotificationsLocalDataSource localDataSource;
  final StorageService storageService;

  NotificationsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.storageService,
  });

  Future<String?> _getToken() async {
    return await storageService.getAuthToken();
  }

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    bool forceRefresh = false,
  }) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return const Right([]);
      }

      // ✅ If force refresh, skip cache and fetch from remote
      if (forceRefresh) {
        try {
          final notifications = await remoteDataSource.getNotifications(token);
          await localDataSource.cacheNotifications(notifications);
          ServerStatusService().markServerUp();
          return Right(notifications);
        } catch (e) {
          // If remote fails, try cache
          final cachedNotifications = await localDataSource
              .getCachedNotifications();
          return Right(cachedNotifications);
        }
      }

      // Normal flow: check cache first
      final cachedNotifications = await localDataSource
          .getCachedNotifications();
      if (cachedNotifications.isNotEmpty) {
        return Right(cachedNotifications);
      }

      // No cache, fetch from remote
      try {
        final notifications = await remoteDataSource.getNotifications(token);
        await localDataSource.cacheNotifications(notifications);
        ServerStatusService().markServerUp();
        return Right(notifications);
      } catch (e) {
        if (e.toString().contains('Connection refused') ||
            e is SocketException) {
          ServerStatusService().markServerDown();
        }
        return const Right([]);
      }
    } on SocketException {
      ServerStatusService().markServerDown();
      return const Right([]);
    } catch (e) {
      debugPrint('⚠️ Failed to fetch notifications: $e');
      return const Right([]);
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

    return errorStr
        .replaceAll('exception: ', '')
        .replaceAll('error: ', '')
        .replaceAll('failed: ', '');
  }
}
