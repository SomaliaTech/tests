import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import '../models/support_contact_model.dart';

abstract class SupportRemoteDataSource {
  Future<SupportContact> getContact();
  Future<SupportContact> updateContact({String? email, String? phoneNumber});
}

class SupportRemoteDataSourceImpl implements SupportRemoteDataSource {
  final http.Client client;
  final StorageService storageService;

  SupportRemoteDataSourceImpl({
    required this.client,
    required this.storageService,
  });

  Future<Map<String, String>> _authHeaders() async {
    final token = await storageService.getAuthToken();
    if (token == null) throw const ServerException('Token not found');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<SupportContact> getContact() async {
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/support/contact'),
    );
    if (response.statusCode == 200) {
      return SupportContact.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ServerException(
      'Failed to load support contact: ${response.statusCode}',
    );
  }

  @override
  Future<SupportContact> updateContact({
    String? email,
    String? phoneNumber,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{};
    if (email != null) body['email'] = email;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;

    final response = await client.patch(
      Uri.parse('${ApiConstants.baseUrl}/admin/support/settings'),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final settings = decoded['settings'] as Map<String, dynamic>? ?? decoded;
      return SupportContact.fromJson(settings);
    }

    final err = json.decode(response.body);
    throw ServerException(err['message']?.toString() ?? 'Update failed');
  }
}
