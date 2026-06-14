import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/tracking.dart';
import '../models/tracking_model.dart';

abstract class TrackingRemoteDataSource {
  Future<TrackingInfo> getTrackingInfo(String token, String orderId);
}

class TrackingRemoteDataSourceImpl implements TrackingRemoteDataSource {
  final http.Client client;

  TrackingRemoteDataSourceImpl({required this.client});

  @override
  Future<TrackingInfo> getTrackingInfo(String token, String orderId) async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/orders/$orderId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return TrackingModel.fromJson(json.decode(response.body));
      } else {
        throw ServerException('Failed to load tracking info');
      }
    } catch (e) {
      throw ServerException('Network error: $e');
    }
  }
}
