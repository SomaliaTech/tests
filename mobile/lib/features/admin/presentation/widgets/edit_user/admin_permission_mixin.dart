// lib/features/admin/presentation/widgets/admin_permission_mixin.dart

import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/core/services/permission_service.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/core/services/injection_container.dart';

mixin AdminPermissionMixin<T extends StatefulWidget> on State<T> {
  bool isSuperAdmin = false;
  List<String> permissions = [];
  bool permissionsLoaded = false;

  Future<void> loadAdminPermissions() async {
    try {
      final storageService = sl<StorageService>();
      final permissionService = GetIt.instance<PermissionService>();

      isSuperAdmin = await storageService.getIsSuperAdmin();
      permissions = await permissionService.loadPermissions(
        forceRefresh: false,
      );

      if (mounted) {
        setState(() {
          permissionsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('❌ [PermissionMixin] Failed: $e');
      if (mounted) {
        setState(() {
          permissionsLoaded = true;
        });
      }
    }
  }

  bool hasPermission(String permission) {
    if (isSuperAdmin) return true;
    if (permissions.contains('*')) return true;
    if (permissions.contains(permission)) return true;

    final module = permission.split(':').first;
    return permissions.contains('$module:manage');
  }

  bool canCreate(String module) => hasPermission('$module:create');
  bool canUpdate(String module) => hasPermission('$module:update');
  bool canDelete(String module) => hasPermission('$module:delete');
  bool canView(String module) => hasPermission('$module:view');
}
