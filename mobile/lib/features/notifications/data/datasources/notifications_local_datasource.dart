import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/notification.dart';

class NotificationsRemoteDataSource {
  final http.Client client;

  NotificationsRemoteDataSource({required this.client});

  Future<List<NotificationEntity>> getNotifications(String token) async {
    try {
      // ✅ FIX: Only log token if it's long enough
      if (token.isNotEmpty) {
        final displayToken = token.length > 20
            ? '${token.substring(0, 20)}...'
            : token;
        print('🔍 Fetching notifications with token: $displayToken');
      } else {
        print('❌ Token is empty');
        throw Exception('Authentication token is empty');
      }

      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📦 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        print('✅ Found ${jsonList.length} notifications');
        return jsonList
            .map((json) => NotificationEntity.fromJson(json))
            .toList();
      } else if (response.statusCode == 401) {
        print('❌ Token expired or invalid');
        throw ServerException('Session expired. Please login again.');
      } else {
        throw ServerException(
          'Failed to load notifications: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Network error: $e');
      throw ServerException('Network error: $e');
    }
  }

  Future<void> markAsRead(String token, String id) async {
    try {
      final response = await client.put(
        Uri.parse('${ApiConstants.baseUrl}/notifications/$id/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to mark notification as read');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  Future<void> markAllAsRead(String token) async {
    try {
      final response = await client.put(
        Uri.parse('${ApiConstants.baseUrl}/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to mark all notifications as read');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  Future<void> deleteNotification(String token, String id) async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiConstants.baseUrl}/notifications/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to delete notification');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  Future<void> clearAllNotifications(String token) async {
    try {
      final response = await client.delete(
        Uri.parse('${ApiConstants.baseUrl}/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to clear notifications');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  Future<int> getUnreadCount(String token) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/notifications/unread/count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['unreadCount'] as int? ?? 0;
      } else {
        throw ServerException('Failed to get unread count');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }
}
