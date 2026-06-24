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
import 'package:mobile/features/admin/domain/entities/chart_data_entity.dart';
import 'package:mobile/features/admin/domain/entities/dashboard_stats_entity.dart';
import 'package:mobile/features/admin/domain/entities/device_traffic_entity.dart';
import 'package:mobile/features/admin/domain/entities/location_traffic_entity.dart';
import 'package:mobile/features/admin/domain/entities/product_traffic_entity.dart';
import 'package:mobile/features/admin/presentation/bloc/dashborad/dashboard_state.dart';

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
    print(
      '🚀 [Dashboard] Fetching ALL data in ONE request for period: $period',
    );
    final stopwatch = Stopwatch()..start();

    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/dashboard/all?period=$period';
      print('📍 [Dashboard] URL: $url');

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 [Dashboard] Response Status: ${response.statusCode}');
      print('⏱️ [Dashboard] Response Time: ${stopwatch.elapsedMilliseconds}ms');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [Dashboard] All data parsed successfully');

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
    } catch (e, stackTrace) {
      print('❌ [Dashboard] Exception: $e');
      print('📚 [Dashboard] Stack trace: $stackTrace');
      rethrow;
    }
  }
}
