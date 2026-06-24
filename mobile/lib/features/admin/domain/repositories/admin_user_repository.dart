import 'package:mobile/features/admin/domain/entities/admin_user_entity.dart';

abstract class AdminUserRepository {
  Future<List<AdminUserEntity>> getAllUsers(String? search);
  Future<AdminUserEntity> getUserById(String userId);
  Future<void> createUser(Map<String, dynamic> userData);
  Future<void> updateUser(String userId, Map<String, dynamic> updateData);
  Future<void> deleteUser(String userId);
}
