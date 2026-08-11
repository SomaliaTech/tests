// lib/features/order/data/datasources/order_remote_datasource.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';

abstract class OrderRemoteDataSource {
  Future<Map<String, dynamic>> createOrder(
    String token,
    Map<String, dynamic> orderData,
  );
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final http.Client client;
  OrderRemoteDataSourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> createOrder(
    String token,
    Map<String, dynamic> orderData,
  ) async {
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(orderData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ServerException('Failed to create order: ${response.body}');
    }
  }
}
