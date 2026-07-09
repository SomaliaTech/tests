import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/admin/data/models/market_model.dart';

abstract class AdminMarketRemoteDataSource {
  Future<List<MarketModel>> getAllMarkets();
  Future<void> createMarket(Map<String, dynamic> data);
  Future<void> updateMarket(String marketId, Map<String, dynamic> data);
  Future<void> deleteMarket(String marketId);
}

class AdminMarketRemoteDataSourceImpl implements AdminMarketRemoteDataSource {
  final http.Client client;
  final StorageService storageService;

  AdminMarketRemoteDataSourceImpl({
    required this.client,
    required this.storageService,
  });

  Future<String> _getToken() async {
    final token = await storageService.getAuthToken();
    if (token == null) throw const ServerException('Token not found');
    return token;
  }

  // admin_market_remote_data_source.dart

  @override
  Future<List<MarketModel>> getAllMarkets() async {
    print('🔍 [AdminMarkets] Fetching all markets');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/markets/all';

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 [AdminMarkets] Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // ✅ Handle both List and Map with 'items' key
        List<dynamic> jsonList;
        if (decoded is List) {
          jsonList = decoded;
        } else if (decoded is Map && decoded.containsKey('items')) {
          jsonList = decoded['items'];
        } else if (decoded is Map && decoded.containsKey('data')) {
          jsonList = decoded['data'];
        } else {
          print('❌ [AdminMarkets] Unexpected response format: $decoded');
          return [];
        }

        return jsonList.map((json) => MarketModel.fromJson(json)).toList();
      } else {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AdminMarkets] Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> createMarket(Map<String, dynamic> data) async {
    print('🔍 [AdminMarkets] Creating market: $data');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/markets';

      final response = await client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      print('📡 [AdminMarkets] Create Response: ${response.statusCode}');

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AdminMarkets] Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateMarket(String marketId, Map<String, dynamic> data) async {
    print('🔍 [AdminMarkets] Updating market: $marketId');
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/markets/$marketId';

      final response = await client.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // In admin_market_remote_data_source_impl.dart

  @override
  Future<void> deleteMarket(String marketId) async {
    try {
      final token = await _getToken();
      final url = '${ApiConstants.baseUrl}/admin/markets/$marketId';

      final response = await client.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('📡 [AdminMarkets] Delete Response: ${response.statusCode}');
      print('📦 [AdminMarkets] Delete Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        final data = json.decode(response.body);
        // ✅ Check if market was deactivated instead of deleted
        if (data['deactivated'] == true) {
          print('⚠️ [AdminMarkets] Market deactivated instead of deleted');
          // Don't throw error, just return
          return;
        }
        return;
      } else {
        final errorData = json.decode(response.body);
        throw ServerException(
          errorData['message'] ?? 'Failed to delete market',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      print('❌ [AdminMarkets] Delete error: $e');
      throw ServerException('Failed to delete market: $e');
    }
  }
}
