import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/order_details.dart';
import '../models/order_details_model.dart';

abstract class OrderDetailsRemoteDataSource {
  Future<OrderDetails> getOrderDetails(String token, String orderId);
}

class OrderDetailsRemoteDataSourceImpl implements OrderDetailsRemoteDataSource {
  final http.Client client;

  OrderDetailsRemoteDataSourceImpl({required this.client});

  @override
  Future<OrderDetails> getOrderDetails(String token, String orderId) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/orders/$orderId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return OrderDetailsModel.fromJson(json.decode(response.body));
      } else {
        throw ServerException('Failed to load order details');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }
}
