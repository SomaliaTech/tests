import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/admin/data/models/chart_data_model.dart';
import 'package:mobile/features/admin/data/models/dashboard_stats_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardStatsModel> getDashboardStats(String period);
  Future<List<ChartDataModel>> getUsersChartData(String period);
  Future<List<DeviceTrafficModel>> getDeviceTraffic();
  Future<List<LocationTrafficModel>> getLocationTraffic();
  Future<List<ProductTrafficModel>> getProductTraffic(String period);
  Future<List<ChartDataModel>> getRevenueChart(String period);
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

  @override
  Future<DashboardStatsModel> getDashboardStats(String period) async {
    final token = await _getToken();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/dashboard/stats?period=$period'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return DashboardStatsModel.fromJson(json.decode(response.body));
    } else {
      throw ServerException('Failed to load stats: ${response.statusCode}');
    }
  }

  @override
  Future<List<ChartDataModel>> getUsersChartData(String period) async {
    final token = await _getToken();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/dashboard/users-chart?period=$period'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => ChartDataModel.fromJson(json)).toList();
    } else {
      throw ServerException('Failed to load chart: ${response.statusCode}');
    }
  }

  @override
  Future<List<DeviceTrafficModel>> getDeviceTraffic() async {
    final token = await _getToken();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/dashboard/device-traffic'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => DeviceTrafficModel.fromJson(json)).toList();
    } else {
      throw ServerException(
        'Failed to load device traffic: ${response.statusCode}',
      );
    }
  }

  @override
  Future<List<LocationTrafficModel>> getLocationTraffic() async {
    final token = await _getToken();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/dashboard/location-traffic'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList
          .map((json) => LocationTrafficModel.fromJson(json))
          .toList();
    } else {
      throw ServerException(
        'Failed to load location traffic: ${response.statusCode}',
      );
    }
  }

  @override
  Future<List<ProductTrafficModel>> getProductTraffic(String period) async {
    final token = await _getToken();
    final response = await client.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/dashboard/product-traffic?period=$period',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList
          .map((json) => ProductTrafficModel.fromJson(json))
          .toList();
    } else {
      throw ServerException(
        'Failed to load product traffic: ${response.statusCode}',
      );
    }
  }

  @override
  Future<List<ChartDataModel>> getRevenueChart(String period) async {
    final token = await _getToken();
    final response = await client.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/dashboard/revenue-chart?period=$period',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => ChartDataModel.fromJson(json)).toList();
    } else {
      throw ServerException(
        'Failed to load revenue chart: ${response.statusCode}',
      );
    }
  }
}
