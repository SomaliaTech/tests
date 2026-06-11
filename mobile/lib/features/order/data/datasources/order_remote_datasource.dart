import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/features/order/data/models/order_model.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/order.dart' as domain;

abstract class OrderRemoteDataSource {
  Future<domain.DomainOrder> createOrder(
    String token,
    Map<String, dynamic> orderData,
  );
  Future<Map<String, dynamic>> processPayment(
    String token,
    String orderId,
    String paymentMethod, {
    String? phoneNumber,
  });
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final http.Client client;
  OrderRemoteDataSourceImpl({required this.client});

  @override
  Future<domain.DomainOrder> createOrder(
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
      final Map<String, dynamic> result = json.decode(response.body);
      return OrderModel.fromJson(result['order']);
    } else {
      throw ServerException('Failed to create order: ${response.body}');
    }
  }

  @override
  Future<Map<String, dynamic>> processPayment(
    String token,
    String orderId,
    String paymentMethod, {
    String? phoneNumber,
  }) async {
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/orders/$orderId/payment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'paymentMethod': paymentMethod,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
      }),
    );

    // 🚨 PRINT THE ACTUAL RESPONSE TO SEE THE REAL ERROR
    print('📥 Payment Response status: ${response.statusCode}');
    print('📥 Payment Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      // Pass the actual backend error message to the UI
      throw ServerException('Payment failed: ${response.body}');
    }
  }
}
