import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/admin/data/models/affiliate_model.dart';
import 'package:mobile/features/admin/data/models/affiliate_request_model.dart';
import 'package:mobile/features/admin/data/models/promo_code_model.dart';

abstract class AffiliateRemoteDataSource {
  // ==========================================
  // USER / AFFILIATE ENDPOINTS
  // ==========================================
  Future<Map<String, dynamic>> getMyAffiliateStats();
  Future<List<Map<String, dynamic>>> getMyPromoCodes();
  Future<List<Map<String, dynamic>>> getMyCommissions({String? status});
  Future<void> createMyPromoCode(Map<String, dynamic> data);
  Future<void> toggleMyPromoCode(String promoCodeId, bool isActive);
  Future<void> deleteMyPromoCode(String promoCodeId);
  Future<void> applyForAffiliate({
    required String businessName,
    String? description,
    String? phoneNumber,
  });
  Future<Map<String, dynamic>> validatePromoCode(
    String code,
    double orderAmount,
  );

  Future<Map<String, dynamic>> getAffiliateSettings();
  Future<Map<String, dynamic>> updateAffiliateSettings(
    Map<String, dynamic> data,
  );

  // ==========================================
  // ADMIN ENDPOINTS
  // ==========================================
  Future<Map<String, dynamic>> getAffiliateDashboard();
  Future<List<AffiliateRequestModel>> getAffiliateRequests({String? status});
  Future<void> approveAffiliateRequest(
    String requestId, {
    double? commissionRate,
  });
  Future<void> rejectAffiliateRequest(String requestId, String reason);
  Future<List<AffiliateModel>> getAllAffiliates({
    String? status,
    String? search,
  });
  Future<AffiliateModel> getAffiliateDetail(String affiliateId);
  Future<void> updateAffiliate(String affiliateId, Map<String, dynamic> data);
  Future<List<PromoCodeModel>> getAllPromoCodes({String? type, bool? isActive});
  Future<void> createSystemPromoCode(Map<String, dynamic> data);
  Future<void> updatePromoCodeByAdmin(
    String promoId,
    Map<String, dynamic> data,
  );
  Future<void> deletePromoCodeByAdmin(String promoCodeId);
  Future<Map<String, dynamic>> getAllCommissions({
    String? status,
    String? affiliateId,
  });
  Future<void> payCommissions(
    List<String> commissionIds, {
    String? paymentNote,
  });
}

class AffiliateRemoteDataSourceImpl implements AffiliateRemoteDataSource {
  final http.Client client;
  final StorageService storageService;

  AffiliateRemoteDataSourceImpl({
    required this.client,
    required this.storageService,
  });

  @override
  Future<Map<String, dynamic>> getAffiliateSettings() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/affiliate/settings'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw ServerException('Failed to load settings: ${response.statusCode}');
  }

  @override
  Future<Map<String, dynamic>> updateAffiliateSettings(
    Map<String, dynamic> data,
  ) async {
    final headers = await _getHeaders();
    final response = await client.patch(
      Uri.parse('${ApiConstants.baseUrl}/admin/affiliate/settings'),
      headers: headers,
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    final error = json.decode(response.body)['message'] ?? 'Failed to save';
    throw ServerException(error);
  }

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

  // ==========================================
  // USER / AFFILIATE IMPLEMENTATIONS
  // ==========================================

  @override
  Future<Map<String, dynamic>> getMyAffiliateStats() async {
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
  Future<List<Map<String, dynamic>>> getMyPromoCodes() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/affiliate/promo-codes'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final list = _extractList(decoded);
      return List<Map<String, dynamic>>.from(list);
    }
    throw ServerException('Failed to load promo codes: ${response.statusCode}');
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
      final list = _extractList(decoded);
      return List<Map<String, dynamic>>.from(list);
    }
    throw ServerException('Failed to load commissions: ${response.statusCode}');
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
  Future<void> applyForAffiliate({
    required String businessName,
    String? description,
    String? phoneNumber,
  }) async {
    final headers = await _getHeaders();
    final body = <String, dynamic>{'businessName': businessName};
    if (description != null) body['description'] = description;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;

    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/affiliate/apply'),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ?? 'Failed to submit application';
        throw ServerException(errorMessage);
      } catch (_) {
        throw ServerException(
          'Failed to submit application: ${response.statusCode}',
        );
      }
    }
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

  // ==========================================
  // ADMIN IMPLEMENTATIONS
  // ==========================================

  @override
  Future<Map<String, dynamic>> getAffiliateDashboard() async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/affiliate/dashboard'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw ServerException('Failed to load dashboard: ${response.statusCode}');
  }

  @override
  Future<List<AffiliateRequestModel>> getAffiliateRequests({
    String? status,
  }) async {
    final headers = await _getHeaders();
    var uri = Uri.parse(
      '${ApiConstants.baseUrl}/admin/affiliate/requests?limit=100',
    );
    if (status != null && status.isNotEmpty) {
      uri = uri.replace(queryParameters: {'status': status, 'limit': '100'});
    }
    final response = await client.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return _extractList(
        decoded,
      ).map((j) => AffiliateRequestModel.fromJson(j)).toList();
    }
    throw ServerException('Failed to load requests: ${response.statusCode}');
  }

  @override
  Future<void> approveAffiliateRequest(
    String requestId, {
    double? commissionRate,
  }) async {
    final headers = await _getHeaders();
    final body = <String, dynamic>{};
    if (commissionRate != null) body['commissionRate'] = commissionRate;

    final response = await client.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/admin/affiliate/requests/$requestId/approve',
      ),
      headers: headers,
      body: json.encode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ServerException('Failed to approve: ${response.statusCode}');
    }
  }

  @override
  Future<void> rejectAffiliateRequest(String requestId, String reason) async {
    final headers = await _getHeaders();
    final response = await client.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/admin/affiliate/requests/$requestId/reject',
      ),
      headers: headers,
      body: json.encode({'rejectionReason': reason}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ServerException('Failed to reject: ${response.statusCode}');
    }
  }

  @override
  Future<List<AffiliateModel>> getAllAffiliates({
    String? status,
    String? search,
  }) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{'limit': '100'};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/admin/affiliate/all',
    ).replace(queryParameters: queryParams);
    final response = await client.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return _extractList(
        decoded,
      ).map((j) => AffiliateModel.fromJson(j)).toList();
    }
    throw ServerException('Failed to load affiliates: ${response.statusCode}');
  }

  @override
  Future<AffiliateModel> getAffiliateDetail(String affiliateId) async {
    final headers = await _getHeaders();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/affiliate/$affiliateId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final affiliateData = decoded['affiliate'] ?? decoded;
      return AffiliateModel.fromJson(affiliateData);
    }
    throw ServerException('Failed to load affiliate: ${response.statusCode}');
  }

  @override
  Future<void> updateAffiliate(
    String affiliateId,
    Map<String, dynamic> data,
  ) async {
    final headers = await _getHeaders();
    final response = await client.patch(
      Uri.parse('${ApiConstants.baseUrl}/admin/affiliate/$affiliateId'),
      headers: headers,
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw ServerException('Failed to update: ${response.statusCode}');
    }
  }

  @override
  Future<List<PromoCodeModel>> getAllPromoCodes({
    String? type,
    bool? isActive,
  }) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{'limit': '200'};
    if (type != null) queryParams['type'] = type;
    if (isActive != null) queryParams['isActive'] = isActive.toString();
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/admin/promo-codes/all',
    ).replace(queryParameters: queryParams);
    final response = await client.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return _extractList(
        decoded,
      ).map((j) => PromoCodeModel.fromJson(j)).toList();
    }
    throw ServerException('Failed to load promo codes: ${response.statusCode}');
  }

  @override
  Future<void> createSystemPromoCode(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/promo-codes'),
      headers: headers,
      body: json.encode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ServerException(
        'Failed to create promo code: ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> updatePromoCodeByAdmin(
    String promoId,
    Map<String, dynamic> data,
  ) async {
    final headers = await _getHeaders();
    final response = await client.patch(
      Uri.parse('${ApiConstants.baseUrl}/admin/promo-codes/$promoId'),
      headers: headers,
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      final error = json.decode(response.body)['message'] ?? 'Failed to update';
      throw ServerException(error);
    }
  }

  @override
  Future<void> deletePromoCodeByAdmin(String promoCodeId) async {
    final headers = await _getHeaders();
    final response = await client.delete(
      Uri.parse('${ApiConstants.baseUrl}/admin/promo-codes/$promoCodeId'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      final error = json.decode(response.body)['message'] ?? 'Failed to delete';
      throw ServerException(error);
    }
  }

  @override
  Future<Map<String, dynamic>> getAllCommissions({
    String? status,
    String? affiliateId,
  }) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{'limit': '200'};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (affiliateId != null && affiliateId.isNotEmpty)
      queryParams['affiliateId'] = affiliateId;
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/admin/affiliate/commissions/all',
    ).replace(queryParameters: queryParams);
    final response = await client.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw ServerException('Failed to load commissions: ${response.statusCode}');
  }

  @override
  Future<void> payCommissions(
    List<String> commissionIds, {
    String? paymentNote,
  }) async {
    final headers = await _getHeaders();
    final body = <String, dynamic>{'commissionIds': commissionIds};
    if (paymentNote != null) body['paymentNote'] = paymentNote;

    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/affiliate/commissions/pay'),
      headers: headers,
      body: json.encode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ServerException(
        'Failed to pay commissions: ${response.statusCode}',
      );
    }
  }
}
