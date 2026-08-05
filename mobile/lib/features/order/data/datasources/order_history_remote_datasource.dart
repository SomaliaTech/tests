// lib/features/order/data/datasources/order_history_remote_datasource.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
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
  // In your Flutter OrderHistoryRemoteDataSourceImpl
  @override
  Future<List<OrderHistory>> getOrders(String token) async {
    try {
      final url = '${ApiConstants.baseUrl}/orders';
      debugPrint('🌐 Calling: $url');
      debugPrint('🔑 Token: ${token.substring(0, 20)}...');

      final response = await client.get(
        Uri.parse(url), // ✅ Make sure no trailing slash or spaces
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📦 Orders response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        List<dynamic> jsonList;

        if (decoded is Map<String, dynamic>) {
          jsonList =
              (decoded['items'] ?? decoded['data'] ?? decoded['orders'] ?? [])
                  as List<dynamic>;
        } else if (decoded is List) {
          jsonList = decoded;
        } else {
          return [];
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
        return []; // Return empty on error instead of throwing
      }
    } catch (e) {
      debugPrint('❌ Network error: $e');
      return []; // Return empty on network error
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

        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') &&
              decoded['data'] is Map<String, dynamic>) {
            orderJson = decoded['data'] as Map<String, dynamic>;
          } else if (decoded.containsKey('order') &&
              decoded['order'] is Map<String, dynamic>) {
            orderJson = decoded['order'] as Map<String, dynamic>;
          } else if (decoded.containsKey('id')) {
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
      } else if (response.statusCode == 403) {
        throw ServerException('You don\'t have permission to view this order');
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
