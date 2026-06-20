import 'dart:convert';
import 'package:http/http.dart' as http;
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
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => MarketModel.fromJson(json)).toList();
      } else {
        throw ServerException('Failed to load markets');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }
}
