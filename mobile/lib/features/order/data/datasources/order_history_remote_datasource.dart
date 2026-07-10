import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:mobile/features/order/data/models/order_history_model.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/order_history.dart';

abstract class OrderHistoryRemoteDataSource {
  Future<List<OrderHistory>> getOrders(String token);
  Future<OrderHistory> getOrderById(String token, String orderId);
}

class OrderHistoryRemoteDataSourceImpl implements OrderHistoryRemoteDataSource {
  final http.Client client;

  OrderHistoryRemoteDataSourceImpl({required this.client});

  @override
  Future<List<OrderHistory>> getOrders(String token) async {
    try {
      debugPrint('🔍 Fetching orders...');

      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📦 Orders response status: ${response.statusCode}');
      debugPrint(
        '📦 Orders response body (first 200 chars): ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        List<dynamic> jsonList;

        // ✅ Handle different response formats
        if (decoded is Map<String, dynamic>) {
          // Check for common keys: 'data', 'orders', 'items', 'results'
          jsonList =
              (decoded['data'] ??
                      decoded['orders'] ??
                      decoded['items'] ??
                      decoded['results'] ??
                      [])
                  as List<dynamic>;
          debugPrint('✅ Found ${jsonList.length} orders (from Map)');
        } else if (decoded is List) {
          // Direct list response
          jsonList = decoded;
          debugPrint('✅ Found ${jsonList.length} orders (from List)');
        } else {
          debugPrint('❌ Unexpected response format: ${decoded.runtimeType}');
          throw ServerException('Invalid response format from server');
        }

        return jsonList
            .map(
              (json) =>
                  OrderHistoryModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else if (response.statusCode == 401) {
        throw ServerException('Session expired. Please login again.');
      } else {
        debugPrint('❌ Failed to load orders: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        throw ServerException('Failed to load orders (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('❌ Network error loading orders: $e');
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<OrderHistory> getOrderById(String token, String orderId) async {
    try {
      debugPrint('🔍 Fetching order: $orderId');

      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/orders/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📦 Order detail status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        Map<String, dynamic> orderJson;

        // ✅ Handle different response formats for single order
        if (decoded is Map<String, dynamic>) {
          // Check if the order is wrapped in a 'data' or 'order' key
          if (decoded.containsKey('data') &&
              decoded['data'] is Map<String, dynamic>) {
            orderJson = decoded['data'] as Map<String, dynamic>;
          } else if (decoded.containsKey('order') &&
              decoded['order'] is Map<String, dynamic>) {
            orderJson = decoded['order'] as Map<String, dynamic>;
          } else if (decoded.containsKey('id')) {
            // Direct order object
            orderJson = decoded;
          } else {
            debugPrint('❌ Unknown order response format');
            throw ServerException('Invalid order response format');
          }

          return OrderHistoryModel.fromJson(orderJson);
        } else {
          throw ServerException('Invalid response format');
        }
      } else if (response.statusCode == 401) {
        throw ServerException('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw ServerException('Order not found');
      } else {
        throw ServerException(
          'Failed to load order details (${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading order $orderId: $e');
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }
}

// ✅ Add import for debugPrint if not already imported
