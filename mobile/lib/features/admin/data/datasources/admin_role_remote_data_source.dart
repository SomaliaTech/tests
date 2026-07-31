// lib/features/admin/data/datasources/admin_role_remote_data_source.dart
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/admin/data/models/role_model.dart';

abstract class AdminRoleRemoteDataSource {
  Future<List<RoleModel>> getAllRoles();
  Future<RoleModel> getRoleById(String roleId);
  Future<RoleModel> createRole(Map<String, dynamic> roleData);
  Future<RoleModel> updateRole(String roleId, Map<String, dynamic> updateData);
  Future<void> deleteRole(String roleId);
  Future<void> assignRoleToUser(String userId, String roleId);
  Future<void> removeRoleFromUser(String userId, String roleId);
  Future<List<RoleModel>> getUserRoles(String userId);
}

class AdminRoleRemoteDataSourceImpl implements AdminRoleRemoteDataSource {
  final http.Client client;
  final StorageService storageService;

  AdminRoleRemoteDataSourceImpl({
    required this.client,
    required this.storageService,
  });

  Future<String> _getToken() async {
    final token = await storageService.getAuthToken();
    if (token == null) throw const ServerException('Token not found');
    return token;
  }

  @override
  Future<List<RoleModel>> getAllRoles() async {
    try {
      final token = await _getToken();
      debugPrint('🔑 [AdminRole] Fetching all roles...');

      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/admin/roles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📡 [AdminRole] Response Status: ${response.statusCode}');
      debugPrint(
        '📡 [AdminRole] Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        List<dynamic> jsonList;
        if (decoded is List) {
          jsonList = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          jsonList = decoded['data'];
        } else if (decoded is Map && decoded.containsKey('items')) {
          jsonList = decoded['items'];
        } else if (decoded is Map && decoded.containsKey('roles')) {
          jsonList = decoded['roles'];
        } else {
          debugPrint('❌ [AdminRole] Unexpected response format: $decoded');
          return [];
        }

        debugPrint('✅ [AdminRole] Found ${jsonList.length} roles');
        return jsonList.map((json) => RoleModel.fromJson(json)).toList();
      } else {
        throw ServerException('Failed to load roles: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [AdminRole] Error: $e');
      rethrow;
    }
  }

  @override
  Future<RoleModel> getRoleById(String roleId) async {
    final token = await _getToken();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/roles/$roleId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final data = decoded is Map && decoded.containsKey('data')
          ? decoded['data']
          : decoded;
      return RoleModel.fromJson(data);
    } else {
      throw ServerException('Failed to load role: ${response.statusCode}');
    }
  }

  @override
  Future<RoleModel> createRole(Map<String, dynamic> roleData) async {
    final token = await _getToken();
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/roles'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(roleData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final data = decoded is Map && decoded.containsKey('data')
          ? decoded['data']
          : decoded;
      return RoleModel.fromJson(data);
    } else {
      throw ServerException('Failed to create role: ${response.statusCode}');
    }
  }

  @override
  Future<RoleModel> updateRole(
    String roleId,
    Map<String, dynamic> updateData,
  ) async {
    final token = await _getToken();
    final response = await client.put(
      Uri.parse('${ApiConstants.baseUrl}/admin/roles/$roleId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(updateData),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final data = decoded is Map && decoded.containsKey('data')
          ? decoded['data']
          : decoded;
      return RoleModel.fromJson(data);
    } else {
      throw ServerException('Failed to update role: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteRole(String roleId) async {
    final token = await _getToken();
    final response = await client.delete(
      Uri.parse('${ApiConstants.baseUrl}/admin/roles/$roleId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ServerException('Failed to delete role: ${response.statusCode}');
    }
  }

  @override
  Future<void> assignRoleToUser(String userId, String roleId) async {
    final token = await _getToken();
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/users/$userId/roles'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'roleId': roleId}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ServerException('Failed to assign role: ${response.statusCode}');
    }
  }

  @override
  Future<void> removeRoleFromUser(String userId, String roleId) async {
    final token = await _getToken();
    final response = await client.delete(
      Uri.parse('${ApiConstants.baseUrl}/admin/users/$userId/roles/$roleId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ServerException('Failed to remove role: ${response.statusCode}');
    }
  }

  // lib/features/admin/data/datasources/admin_role_remote_data_source.dart
  @override
  Future<List<RoleModel>> getUserRoles(String userId) async {
    final token = await _getToken();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/users/$userId/roles'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      List<dynamic> jsonList;
      if (decoded is List) {
        jsonList = decoded;
      } else if (decoded is Map && decoded.containsKey('data')) {
        jsonList = decoded['data'];
      } else if (decoded is Map && decoded.containsKey('items')) {
        jsonList = decoded['items'];
      } else {
        return [];
      }

      return jsonList.map((json) => RoleModel.fromJson(json)).toList();
    } else {
      throw ServerException(
        'Failed to load user roles: ${response.statusCode}',
      );
    }
  }
}
