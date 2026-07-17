import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/order_details.dart';
import '../models/order_details_model.dart';

abstract class OrderDetailsRemoteDataSource {
  Future<OrderDetails> getOrderDetails(
    String token,
    String orderId, {
    bool isAdmin = false,
    bool isSuperAdmin = false,
  });
}

class OrderDetailsRemoteDataSourceImpl implements OrderDetailsRemoteDataSource {
  final http.Client client;

  OrderDetailsRemoteDataSourceImpl({required this.client});

  @override
  Future<OrderDetails> getOrderDetails(
    String token,
    String orderId, {
    bool isAdmin = false,
    bool isSuperAdmin = false,
  }) async {
    try {
      final isAdminUser = isAdmin || isSuperAdmin;
      final url = isAdminUser
          ? '${ApiConstants.baseUrl}/admin/revenue/$orderId'
          : '${ApiConstants.baseUrl}/orders/$orderId';

      print(
        '🔍 [OrderDetails] Fetching: $url (admin: $isAdmin, superAdmin: $isSuperAdmin)',
      );

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 [OrderDetails] Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return OrderDetailsModel.fromJson(data);
      } else if (response.statusCode == 403) {
        throw ServerException('You do not have permission to view this order');
      } else if (response.statusCode == 404) {
        throw ServerException('Order not found');
      } else {
        throw ServerException(
          'Failed to load order details: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ [OrderDetails] Error: $e');
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }
}
