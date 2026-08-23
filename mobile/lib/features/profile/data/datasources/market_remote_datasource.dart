// lib/features/profile/data/datasources/market_remote_datasource.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/market.dart';
import '../models/market_model.dart';

abstract class MarketRemoteDataSource {
  Future<List<Market>> getMarkets();
}

class MarketRemoteDataSourceImpl implements MarketRemoteDataSource {
  final http.Client client;

  MarketRemoteDataSourceImpl({required this.client});

  @override
  Future<List<Market>> getMarkets() async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/markets'),
        headers: ApiConstants.headers,
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        // ✅ Handle both array and paginated response
        List<dynamic> jsonList;

        if (responseData is Map && responseData.containsKey('items')) {
          // Paginated response: { items: [...], pagination: {...} }
          jsonList = responseData['items'] as List<dynamic>;
          debugPrint(
            '📊 Parsed paginated markets response: ${jsonList.length} items',
          );
        } else if (responseData is List) {
          // Direct array response: [...]
          jsonList = responseData;
          debugPrint(
            '📊 Parsed array markets response: ${jsonList.length} items',
          );
        } else {
          throw ServerException(
            'Unexpected response format: ${responseData.runtimeType}',
          );
        }

        final markets = jsonList
            .map((json) => MarketModel.fromJson(json as Map<String, dynamic>))
            .toList();

        debugPrint('✅ Successfully loaded ${markets.length} markets');
        return markets;
      } else {
        throw ServerException(
          'Failed to load markets. Status code: ${response.statusCode}',
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      debugPrint('❌ Market loading error: $e');
      throw ServerException('Network error: $e');
    }
  }
}
