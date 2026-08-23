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
      print(
        '📦 Response body (first 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // ✅ Handle different response formats
        List<dynamic> jsonList;

        if (decoded is List) {
          // Direct array response
          jsonList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          // Check for common wrapper keys
          if (decoded.containsKey('data') && decoded['data'] is List) {
            jsonList = decoded['data'];
          } else if (decoded.containsKey('items') && decoded['items'] is List) {
            jsonList = decoded['items'];
          } else if (decoded.containsKey('notifications') &&
              decoded['notifications'] is List) {
            jsonList = decoded['notifications'];
          } else if (decoded.containsKey('results') &&
              decoded['results'] is List) {
            jsonList = decoded['results'];
          } else {
            // Unknown format - log and return empty
            print('⚠️ Unknown response format: $decoded');
            return [];
          }
        } else {
          print('⚠️ Unexpected response type: ${decoded.runtimeType}');
          return [];
        }

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
      if (e is ServerException) rethrow;
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
