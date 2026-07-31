// lib/features/admin/domain/repositories/admin_role_repository.dart

import 'package:mobile/features/admin/domain/entities/permission_entity.dart';

// lib/features/admin/domain/repositories/admin_role_repository.dart
abstract class AdminRoleRepository {
  Future<List<RoleEntity>> getAllRoles();
  Future<RoleEntity> getRoleById(String roleId);
  Future<RoleEntity> createRole(Map<String, dynamic> roleData);
  Future<RoleEntity> updateRole(String roleId, Map<String, dynamic> updateData);
  Future<void> deleteRole(String roleId);
  Future<void> assignRoleToUser(String userId, String roleId);
  Future<void> removeRoleFromUser(String userId, String roleId);
  Future<List<RoleEntity>> getUserRoles(String userId); // ✅ Add this
}
