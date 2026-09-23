import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/admin/data/models/admin_stats_model.dart';
import 'package:mobile/features/admin/data/models/admin_order_model.dart';
import 'package:flutter/foundation.dart';

abstract class AdminRemoteDataSource {
  Future<AdminStatsModel> getDashboardStats();
  Future<List<AdminOrderModel>> getAllOrders(String? search);
  Future<void> updateOrderStatus(String orderId, String newStatus);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final http.Client client;
  final StorageService storageService;

  AdminRemoteDataSourceImpl({
    required this.client,
    required this.storageService,
  });

  Future<String> _getToken() async {
    final token = await storageService.getAuthToken();
    if (token == null) throw ServerException('Token not found');
    return token;
  }

  @override
  Future<AdminStatsModel> getDashboardStats() async {
    final token = await _getToken();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      // Handle both wrapped and direct object
      final data = decoded is Map && decoded.containsKey('stats')
          ? decoded['stats']
          : decoded;
      return AdminStatsModel.fromJson(data);
    } else {
      throw ServerException('Failed to load stats: ${response.statusCode}');
    }
  }

  @override
  Future<List<AdminOrderModel>> getAllOrders(String? search) async {
    final token = await _getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}/admin/orders');
    final finalUri = search != null && search.isNotEmpty
        ? uri.replace(queryParameters: {'search': search})
        : uri;

    final response = await client.get(
      finalUri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      // ✅ Handle both List and Map responses
      List<dynamic> jsonList;

      if (decoded is List) {
        // Direct array response
        jsonList = decoded;
      } else if (decoded is Map<String, dynamic>) {
        // Object response - check for orders/data/items key
        if (decoded.containsKey('orders') && decoded['orders'] is List) {
          jsonList = decoded['orders'];
        } else if (decoded.containsKey('data') && decoded['data'] is List) {
          jsonList = decoded['data'];
        } else if (decoded.containsKey('items') && decoded['items'] is List) {
          jsonList = decoded['items'];
        } else {
          if (kDebugMode)
            debugPrint('⚠️ Unknown response format keys: ${decoded.keys}');
          return [];
        }
      } else {
        if (kDebugMode)
          debugPrint('⚠️ Unexpected response type: ${decoded.runtimeType}');
        return [];
      }

      return jsonList.map((json) => AdminOrderModel.fromJson(json)).toList();
    } else {
      throw ServerException('Failed to load orders: ${response.statusCode}');
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final token = await _getToken();
    final url = '${ApiConstants.baseUrl}/admin/orders/$orderId/status';

    if (kDebugMode) debugPrint('🔄 [ADMIN] Updating order status...');
    if (kDebugMode) debugPrint('📍 URL: $url');
    if (kDebugMode) debugPrint('📦 Order ID: $orderId');
    if (kDebugMode) debugPrint('🎯 New Status: $newStatus');

    final response = await client.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'status': newStatus}),
    );

    if (kDebugMode)
      debugPrint('📡 Response Status Code: ${response.statusCode}');
    if (kDebugMode) debugPrint('📥 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      if (kDebugMode) debugPrint('✅ [ADMIN] Order status updated successfully');
    } else {
      if (kDebugMode)
        debugPrint('❌ [ADMIN] Failed to update status: ${response.statusCode}');
      if (kDebugMode) debugPrint('❌ Error details: ${response.body}');
      throw ServerException('Failed to update status: ${response.statusCode}');
    }
  }
}
