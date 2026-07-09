import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import '../models/analytics_models.dart';

abstract class AnalyticsRemoteDataSource {
  Future<AnalyticsDataModel> getAllAnalytics({String period = 'week'});
}

class AnalyticsRemoteDataSourceImpl implements AnalyticsRemoteDataSource {
  final http.Client client;
  final StorageService storageService;

  AnalyticsRemoteDataSourceImpl({
    required this.client,
    required this.storageService,
  });

  Future<String> _getToken() async {
    final token = await storageService.getAuthToken();
    if (token == null) throw const ServerException('Token not found');
    return token;
  }

  @override
  Future<AnalyticsDataModel> getAllAnalytics({String period = 'week'}) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/admin/analytics/all',
      ).replace(queryParameters: {'period': period});

      debugPrint('🔍 [Analytics] GET $uri');

      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📡 [Analytics] Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return AnalyticsDataModel.fromJson(json.decode(response.body));
      } else {
        throw ServerException(
          'Failed to load analytics: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ [Analytics] Error: $e');
      rethrow;
    }
  }
}
