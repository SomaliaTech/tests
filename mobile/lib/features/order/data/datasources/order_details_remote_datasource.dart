// lib/features/order/data/datasources/order_details_remote_datasource.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    final isAdminUser = isAdmin || isSuperAdmin;

    // ✅ Try admin endpoint first, fall back to user endpoint if it fails
    final urls = isAdminUser
        ? <String>[
            '${ApiConstants.baseUrl}/admin/revenue/$orderId',
            '${ApiConstants.baseUrl}/orders/$orderId',
          ]
        : <String>['${ApiConstants.baseUrl}/orders/$orderId'];

    ServerException? lastError;

    for (final url in urls) {
      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          if (kDebugMode) {
            debugPrint(
              '🔍 [OrderDetails] GET $url (admin: $isAdmin, super: $isSuperAdmin)',
            );
          }

          final response = await client.get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (kDebugMode) {
            debugPrint('📡 [OrderDetails] Status: ${response.statusCode}');
          }

          if (response.statusCode == 200) {
            final decoded = json.decode(response.body);

            Map<String, dynamic> orderJson;
            if (decoded is Map<String, dynamic>) {
              if (decoded['data'] is Map<String, dynamic>) {
                orderJson = decoded['data'] as Map<String, dynamic>;
              } else if (decoded['order'] is Map<String, dynamic>) {
                orderJson = decoded['order'] as Map<String, dynamic>;
              } else {
                orderJson = decoded;
              }
            } else {
              throw ServerException('Invalid response format');
            }

            return OrderDetailsModel.fromJson(orderJson);
          }

          // 429 → retry once with 2s backoff
          if (response.statusCode == 429 && attempt == 0) {
            if (kDebugMode) {
              debugPrint('⏳ [OrderDetails] 429 — retrying in 2s...');
            }
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }

          // 429 after retry → try the next URL (fall back)
          if (response.statusCode == 429) {
            lastError = ServerException('Too many requests. Please wait.');
            break; // try next URL
          }

          if (response.statusCode == 403) {
            lastError = ServerException(
              'You do not have permission to view this order',
            );
            break; // try next URL
          }

          if (response.statusCode == 404) {
            lastError = ServerException('Order not found');
            break;
          }

          lastError = ServerException(
            'Failed to load order details: ${response.statusCode}',
          );
          break;
        } catch (e) {
          if (kDebugMode) debugPrint('❌ [OrderDetails] Error: $e');
          if (e is ServerException) {
            lastError = e;
          } else {
            lastError = ServerException('Network error: $e');
          }
          break;
        }
      }
    }

    throw lastError ?? ServerException('Failed to load order details');
  }
}
