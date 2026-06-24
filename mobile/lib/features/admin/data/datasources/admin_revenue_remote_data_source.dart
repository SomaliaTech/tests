import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/admin/data/models/admin_revenue_model.dart';

abstract class AdminRevenueRemoteDataSource {
  Future<AdminRevenueSummaryModel> getRevenueSummary(String period);
  Future<({List<AdminRevenueListModel> data, int total})> getAllRevenue({
    String? search,
    String? paymentMethod,
    String? status,
    int limit,
    int offset,
  });
  Future<AdminRevenueModel> getRevenueById(String orderId);
}

class AdminRevenueRemoteDataSourceImpl implements AdminRevenueRemoteDataSource {
  final http.Client client;
  final StorageService storageService;

  AdminRevenueRemoteDataSourceImpl({
    required this.client,
    required this.storageService,
  });

  Future<String> _getToken() async {
    final token = await storageService.getAuthToken();
    if (token == null) throw ServerException('Token not found');
    return token;
  }

  @override
  Future<AdminRevenueSummaryModel> getRevenueSummary(String period) async {
    print('🔍 [Revenue] Fetching summary for period: $period');
    try {
      final token = await _getToken();
      final url =
          '${ApiConstants.baseUrl}/admin/revenue/summary?period=$period';

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 [Revenue] Summary Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return AdminRevenueSummaryModel.fromJson(json.decode(response.body));
      } else {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [Revenue] Error: $e');
      rethrow;
    }
  }

  @override
  Future<({List<AdminRevenueListModel> data, int total})> getAllRevenue({
    String? search,
    String? paymentMethod,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    print('🔍 [Revenue] Fetching all revenue records');
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConstants.baseUrl}/admin/revenue').replace(
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
          if (status != null) 'status': status,
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 [Revenue] List Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['data'] as List)
            .map((json) => AdminRevenueListModel.fromJson(json))
            .toList();
        // ✅ Explicitly cast total to int
        final total = data['total'] as int? ?? 0;
        return (data: list, total: total);
      } else {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [Revenue] Error: $e');
      rethrow;
    }
  }

  @override
  Future<AdminRevenueModel> getRevenueById(String orderId) async {
    print('🔍 [Revenue] Fetching details for order: $orderId');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/revenue/$orderId';

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 [Revenue] Details Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return AdminRevenueModel.fromJson(json.decode(response.body));
      } else {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [Revenue] Error: $e');
      rethrow;
    }
  }
}
