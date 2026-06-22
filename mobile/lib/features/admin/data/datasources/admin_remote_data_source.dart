import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/admin/data/models/admin_stats_model.dart';
import 'package:mobile/features/admin/data/models/admin_order_model.dart';

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
    if (token == null) throw const ServerException('Token not found');
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
      return AdminStatsModel.fromJson(json.decode(response.body));
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
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => AdminOrderModel.fromJson(json)).toList();
    } else {
      throw ServerException('Failed to load orders: ${response.statusCode}');
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final token = await _getToken();
    final url = '${ApiConstants.baseUrl}/admin/orders/$orderId/status';

    // 🐛 DEBUG LOGGING
    print('🔄 [ADMIN] Updating order status...');
    print('📍 URL: $url');
    print('📦 Order ID: $orderId');
    print('🎯 New Status: $newStatus');
    print('🔑 Token: ${token.substring(0, 20)}...');

    final response = await client.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'status': newStatus}),
    );

    // 🐛 DEBUG LOGGING
    print('📡 Response Status Code: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ [ADMIN] Order status updated successfully');
      return;
    } else {
      print('❌ [ADMIN] Failed to update status: ${response.statusCode}');
      print('❌ Error details: ${response.body}');
      throw ServerException('Failed to update status: ${response.statusCode}');
    }
  }
}
