import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/admin/data/models/promo_code_model.dart';

abstract class AffiliateUserRemoteDataSource {
  Future<void> applyForAffiliate({
    required String businessName,
    String? description,
    String? phoneNumber,
    Map<String, dynamic>? socialMediaLinks,
    int? expectedAudience,
  });
  Future<Map<String, dynamic>?> getMyAffiliateProfile();
  Future<Map<String, dynamic>> getMyDashboardStats();
  Future<List<PromoCodeModel>> getMyPromoCodes();
  Future<void> createMyPromoCode(Map<String, dynamic> data);
  Future<void> toggleMyPromoCode(String promoCodeId, bool isActive);
  Future<void> deleteMyPromoCode(String promoCodeId);
  Future<List<Map<String, dynamic>>> getMyCommissions({String? status});
  Future<Map<String, dynamic>> validatePromoCode(
    String code,
    double orderAmount,
  );
}

class AffiliateUserRemoteDataSourceImpl
    implements AffiliateUserRemoteDataSource {
  final http.Client client;
  final StorageService storageService;

  AffiliateUserRemoteDataSourceImpl({
    required this.client,
    required this.storageService,
  });

  Future<Map<String, String>> _getHeaders() async {
    final token = await storageService.getAuthToken();
    if (token == null) throw const ServerException('Token not found');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      if (decoded.containsKey('items')) return decoded['items'];
      if (decoded.containsKey('data')) return decoded['data'];
    }
    return [];
  }

  @override
  @override
  Future<void> applyForAffiliate({
    required String businessName,
    String? description,
    String? phoneNumber,
    Map<String, dynamic>? socialMediaLinks,
    int? expectedAudience,
  }) async {
    final headers = await _getHeaders();

    final body = <String, dynamic>{'businessName': businessName};
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      body['phoneNumber'] = phoneNumber;
    }
    if (socialMediaLinks != null && socialMediaLinks.isNotEmpty) {
      body['socialMediaLinks'] = socialMediaLinks;
    }
    if (expectedAudience != null) {
      body['expectedAudience'] = expectedAudience;
    }

    if (kDebugMode) {
      debugPrint('📤 [Apply HTTP] POST /affiliate/apply');
      debugPrint('📤 [Apply HTTP] Body: ${json.encode(body)}');
    }

    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/affiliate/apply'),
      headers: headers,
      body: json.encode(body),
    );

    if (kDebugMode) {
      debugPrint('📥 [Apply HTTP] Status: ${response.statusCode}');
      debugPrint('📥 [Apply HTTP] Response: ${response.body}');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      String errorMessage = 'Failed to submit application';
      try {
        final decoded = json.decode(response.body);
        // Nest usually returns: { statusCode, message, error }
        if (decoded is Map) {
          final msg = decoded['message'];
          if (msg is List) {
            errorMessage = msg.join(', '); // validation errors array
          } else if (msg is String) {
            errorMessage = msg;
          } else if (decoded['error'] is String) {
            errorMessage = decoded['error'];
          }
        }
      } catch (_) {}
      throw ServerException(errorMessage);
    }
  }

  @override
  Future<Map<String, dynamic>?> getMyAffiliateProfile() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/affiliate/my-status'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 404) return null;
    throw ServerException('Failed to load profile: ${response.statusCode}');
  }

  @override
  Future<Map<String, dynamic>> getMyDashboardStats() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/affiliate/my-stats'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw ServerException('Failed to load stats: ${response.statusCode}');
  }

  @override
  Future<List<PromoCodeModel>> getMyPromoCodes() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/affiliate/promo-codes'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return _extractList(
        decoded,
      ).map((j) => PromoCodeModel.fromJson(j)).toList();
    }
    throw ServerException('Failed to load promo codes: ${response.statusCode}');
  }

  @override
  Future<void> createMyPromoCode(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/affiliate/promo-codes'),
      headers: headers,
      body: json.encode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = json.decode(response.body)['message'] ?? 'Failed to create';
      throw ServerException(error);
    }
  }

  @override
  Future<void> toggleMyPromoCode(String promoCodeId, bool isActive) async {
    final headers = await _getHeaders();
    final response = await client.patch(
      Uri.parse('${ApiConstants.baseUrl}/affiliate/promo-codes/$promoCodeId'),
      headers: headers,
      body: json.encode({'isActive': isActive}),
    );
    if (response.statusCode != 200) {
      throw ServerException('Failed to update code: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteMyPromoCode(String promoCodeId) async {
    final headers = await _getHeaders();
    final response = await client.delete(
      Uri.parse('${ApiConstants.baseUrl}/affiliate/promo-codes/$promoCodeId'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      final error = json.decode(response.body)['message'] ?? 'Failed to delete';
      throw ServerException(error);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMyCommissions({String? status}) async {
    final headers = await _getHeaders();
    var uri = Uri.parse('${ApiConstants.baseUrl}/affiliate/commissions');
    if (status != null && status != 'ALL' && status.isNotEmpty) {
      uri = uri.replace(queryParameters: {'status': status});
    }
    final response = await client.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return List<Map<String, dynamic>>.from(_extractList(decoded));
    }
    throw ServerException('Failed to load commissions: ${response.statusCode}');
  }

  @override
  Future<Map<String, dynamic>> validatePromoCode(
    String code,
    double orderAmount,
  ) async {
    final headers = await _getHeaders();
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/affiliate/promo-codes/validate'),
      headers: headers,
      body: json.encode({
        'code': code.toUpperCase(),
        'orderAmount': orderAmount,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    try {
      final decoded = json.decode(response.body);
      throw ServerException(decoded['message'] ?? 'Invalid promo code');
    } catch (_) {
      throw ServerException(
        'Failed to validate promo code: ${response.statusCode}',
      );
    }
  }
}
