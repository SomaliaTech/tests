// lib/features/admin/data/repositories/admin_role_repository_impl.dart
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/admin/data/datasources/admin_role_remote_data_source.dart';
import 'package:mobile/features/admin/domain/entities/permission_entity.dart';
import 'package:mobile/features/admin/domain/repositories/admin_role_repository.dart';

class AdminRoleRepositoryImpl implements AdminRoleRepository {
  final AdminRoleRemoteDataSource remoteDataSource;

  AdminRoleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<RoleEntity>> getAllRoles() async {
    try {
      final roles = await remoteDataSource.getAllRoles();
      return roles.map((role) => role.toEntity()).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to get roles: $e');
    }
  }

  @override
  Future<RoleEntity> getRoleById(String roleId) async {
    try {
      final role = await remoteDataSource.getRoleById(roleId);
      return role.toEntity();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to get role: $e');
    }
  }

  @override
  Future<RoleEntity> createRole(Map<String, dynamic> roleData) async {
    try {
      final role = await remoteDataSource.createRole(roleData);
      return role.toEntity();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to create role: $e');
    }
  }

  @override
  Future<RoleEntity> updateRole(
    String roleId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final role = await remoteDataSource.updateRole(roleId, updateData);
      return role.toEntity();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to update role: $e');
    }
  }

  @override
  Future<void> deleteRole(String roleId) async {
    try {
      await remoteDataSource.deleteRole(roleId);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to delete role: $e');
    }
  }

  @override
  Future<void> assignRoleToUser(String userId, String roleId) async {
    try {
      await remoteDataSource.assignRoleToUser(userId, roleId);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to assign role: $e');
    }
  }

  @override
  Future<void> removeRoleFromUser(String userId, String roleId) async {
    try {
      await remoteDataSource.removeRoleFromUser(userId, roleId);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to remove role: $e');
    }
  }

  @override
  Future<List<RoleEntity>> getUserRoles(String userId) async {
    try {
      final roles = await remoteDataSource.getUserRoles(userId);
      return roles.map((role) => role.toEntity()).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to get user roles: $e');
    }
  }
}
