import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/admin/data/models/admin_user_model.dart';

abstract class AdminUserRemoteDataSource {
  Future<List<AdminUserModel>> getAllUsers(String? search);
  Future<AdminUserModel> getUserById(String userId);
  Future<void> createUser(Map<String, dynamic> userData);
  Future<void> updateUser(String userId, Map<String, dynamic> updateData);
  Future<void> deleteUser(String userId);
}

class AdminUserRemoteDataSourceImpl implements AdminUserRemoteDataSource {
  final http.Client client;
  final StorageService storageService;

  AdminUserRemoteDataSourceImpl({
    required this.client,
    required this.storageService,
  });

  Future<String> _getToken() async {
    final token = await storageService.getAuthToken();
    if (token == null) throw const ServerException('Token not found');
    return token;
  }

  @override
  Future<List<AdminUserModel>> getAllUsers(String? search) async {
    final token = await _getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}/admin/users');
    final finalUri = search != null && search.isNotEmpty
        ? uri.replace(queryParameters: {'search': search})
        : uri;

    final response = await client.get(
      finalUri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => AdminUserModel.fromJson(json)).toList();
    } else {
      throw ServerException('Failed to load users: ${response.statusCode}');
    }
  }

  @override
  Future<AdminUserModel> getUserById(String userId) async {
    final token = await _getToken();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return AdminUserModel.fromJson(json.decode(response.body));
    } else {
      throw ServerException('Failed to load user: ${response.statusCode}');
    }
  }

  @override
  Future<void> createUser(Map<String, dynamic> userData) async {
    final token = await _getToken();
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(userData),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ServerException('Failed to create user: ${response.statusCode}');
    }
  }

  @override
  Future<void> updateUser(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    final token = await _getToken();
    final response = await client.put(
      Uri.parse('${ApiConstants.baseUrl}/admin/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(updateData),
    );

    if (response.statusCode != 200) {
      throw ServerException('Failed to update user: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    final token = await _getToken();
    final response = await client.delete(
      Uri.parse('${ApiConstants.baseUrl}/admin/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw ServerException('Failed to delete user: ${response.statusCode}');
    }
  }
}
