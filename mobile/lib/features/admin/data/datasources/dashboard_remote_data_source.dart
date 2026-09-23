import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/admin/data/models/chart_data_model.dart';
import 'package:mobile/features/admin/data/models/dashboard_stats_model.dart';
import 'package:mobile/features/admin/data/models/device_traffic_model.dart';
import 'package:mobile/features/admin/data/models/location_traffic_model.dart';
import 'package:mobile/features/admin/data/models/product_traffic_model.dart';

import 'package:mobile/features/admin/presentation/bloc/dashborad/dashboard_state.dart';
import 'package:flutter/foundation.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardLoaded> getAllDashboardData(String period);
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final http.Client client;
  final StorageService storageService;

  DashboardRemoteDataSourceImpl({
    required this.client,
    required this.storageService,
  });

  Future<String> _getToken() async {
    final token = await storageService.getAuthToken();
    if (token == null) throw const ServerException('Token not found');
    return token;
  }

  // ✅ OPTIMIZED: Single API call for all dashboard data
  @override
  Future<DashboardLoaded> getAllDashboardData(String period) async {
    final stopwatch = Stopwatch()..start();

    try {
      final token = await _getToken();

      _debugToken(token);
      final url = '${ApiConstants.baseUrl}/admin/dashboard/all?period=$period';
      if (kDebugMode) debugPrint('📍 [Dashboard] URL: $url');

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return DashboardLoaded(
          stats: DashboardStatsModel.fromJson(data['stats']),
          usersChartData: (data['usersChartData'] as List)
              .map((json) => ChartDataModel.fromJson(json).toEntity())
              .toList(),
          revenueChartData: (data['revenueChartData'] as List)
              .map((json) => ChartDataModel.fromJson(json).toEntity())
              .toList(),
          deviceTraffic: (data['deviceTraffic'] as List)
              .map((json) => DeviceTrafficModel.fromJson(json).toEntity())
              .toList(),
          locationTraffic: (data['locationTraffic'] as List)
              .map((json) => LocationTrafficModel.fromJson(json).toEntity())
              .toList(),
          productTraffic: (data['productTraffic'] as List)
              .map((json) => ProductTrafficModel.fromJson(json).toEntity())
              .toList(),
          period: period,
        );
      } else {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  void _debugToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return;
      }

      // Decode the payload (middle part)
      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      final jsonPayload = json.decode(decoded);
    } catch (e) {
      ServerException(e.toString());
    }
  }
}
