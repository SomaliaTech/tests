// lib/features/notifications/data/datasources/notifications_local_datasource.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobile/features/notifications/domain/entities/notification.dart';

abstract class NotificationsLocalDataSource {
  Future<List<NotificationEntity>> getCachedNotifications();
  Future<void> cacheNotifications(List<NotificationEntity> notifications);
  Future<void> clearCache();
}

class NotificationsLocalDataSourceImpl implements NotificationsLocalDataSource {
  static const String _boxName = 'notifications_cache';
  static const String _notificationsKey = 'cached_notifications';

  Box<String> get _box => Hive.box<String>(_boxName);

  @override
  Future<List<NotificationEntity>> getCachedNotifications() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox<String>(_boxName);
      }

      final jsonString = _box.get(_notificationsKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map(
              (json) =>
                  NotificationEntity.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('❌ Error reading cached notifications: $e');
    }
    return [];
  }

  @override
  Future<void> cacheNotifications(
    List<NotificationEntity> notifications,
  ) async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox<String>(_boxName);
      }

      final jsonList = notifications
          .map((n) => _notificationToJson(n))
          .toList();
      await _box.put(_notificationsKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('❌ Error caching notifications: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox<String>(_boxName);
      }
      await _box.clear();
      debugPrint('🗑️ Notifications cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  Map<String, dynamic> _notificationToJson(NotificationEntity notification) {
    return {
      'id': notification.id,
      // ✅ FIXED: Use .name instead of .displayName for proper enum deserialization later
      'type': notification.type.name,
      'title': notification.title,
      'message': notification.message,
      'createdAt': notification.date.toIso8601String(),
      'isRead': notification.read,
      'actionText': notification.actionText,
      'actionLink': notification.actionLink,
      'imageUrl': notification.imageUrl,
    };
  }
}
