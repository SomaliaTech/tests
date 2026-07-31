// lib/core/services/permission_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/admin_permissions.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/services/storage/storage_service.dart';

class PermissionService {
  final StorageService storageService;
  final http.Client client;

  List<String> _permissions = [];
  bool _loaded = false;

  PermissionService({required this.storageService, required this.client});

  Future<List<String>> loadPermissions({bool forceRefresh = false}) async {
    if (_loaded && !forceRefresh) {
      return _permissions;
    }

    try {
      // ✅ Super admin sees everything
      final isSuperAdmin = await storageService.getIsSuperAdmin();

      if (isSuperAdmin) {
        _permissions = ['*'];
        _loaded = true;
        await storageService.savePermissions(_permissions);
        return _permissions;
      }

      final token = await storageService.getAuthToken();

      if (token == null || token.isEmpty) {
        _permissions = await storageService.getPermissions();
        _loaded = true;
        return _permissions;
      }

      final response = await client
          .get(
            Uri.parse('${ApiConstants.baseUrl}/admin/me/permissions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));
      debugPrint('🔐 [PermissionService] status: ${response.statusCode}');
      debugPrint('🔐 [PermissionService] body: ${response.body}');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        final list = decoded is Map ? decoded['permissions'] : decoded;

        _permissions = List<String>.from(list ?? []);
        await storageService.savePermissions(_permissions);
      } else {
        debugPrint(
          '❌ [PermissionService] Failed: ${response.statusCode} ${response.body}',
        );
        _permissions = await storageService.getPermissions();
      }
    } catch (e) {
      debugPrint('❌ [PermissionService] Error: $e');
      _permissions = await storageService.getPermissions();
    }

    _loaded = true;
    return _permissions;
  }

  Future<bool> has(String permission) async {
    final permissions = await loadPermissions();
    return AdminPermissions.has(permissions, permission);
  }

  void invalidate() {
    _loaded = false;
  }
}
