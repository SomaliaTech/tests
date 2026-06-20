// lib/features/profile/data/datasources/market_remote_datasource.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/market.dart';

abstract class MarketRemoteDataSource {
  Future<List<Market>> getMarkets();
  Future<Market> getMarketById(String id);
  Future<Market> getMarketBySlug(String slug);
}

class MarketRemoteDataSourceImpl implements MarketRemoteDataSource {
  final http.Client client;

  MarketRemoteDataSourceImpl({required this.client});

  @override
  Future<List<Market>> getMarkets() async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/markets'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Market.fromJson(json)).toList();
      } else {
        throw ServerException('Failed to load markets');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<Market> getMarketById(String id) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/markets/$id'),
      );

      if (response.statusCode == 200) {
        return Market.fromJson(json.decode(response.body));
      } else {
        throw ServerException('Failed to load market');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }

  @override
  Future<Market> getMarketBySlug(String slug) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/markets/slug/$slug'),
      );

      if (response.statusCode == 200) {
        return Market.fromJson(json.decode(response.body));
      } else {
        throw ServerException('Failed to load market');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }
}
