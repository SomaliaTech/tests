import 'dart:convert';
import 'package:http/http.dart' as http;
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
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/orders'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList
            .map((json) => OrderHistoryModel.fromJson(json))
            .toList();
      } else {
        throw ServerException('Failed to load orders');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<OrderHistory> getOrderById(String token, String orderId) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/orders/$orderId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return OrderHistoryModel.fromJson(json.decode(response.body));
      } else {
        throw ServerException('Failed to load order details');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }
}
