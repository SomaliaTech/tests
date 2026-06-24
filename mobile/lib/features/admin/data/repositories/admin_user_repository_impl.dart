import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/admin/data/datasources/admin_user_remote_data_source.dart';
import 'package:mobile/features/admin/domain/entities/admin_user_entity.dart';
import 'package:mobile/features/admin/domain/repositories/admin_user_repository.dart';

class AdminUserRepositoryImpl implements AdminUserRepository {
  final AdminUserRemoteDataSource remoteDataSource;

  AdminUserRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<AdminUserEntity>> getAllUsers(String? search) async {
    try {
      return await remoteDataSource.getAllUsers(search);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<AdminUserEntity> getUserById(String userId) async {
    try {
      return await remoteDataSource.getUserById(userId);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      await remoteDataSource.createUser(userData);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> updateUser(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await remoteDataSource.updateUser(userId, updateData);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await remoteDataSource.deleteUser(userId);
    } on ServerException {
      rethrow;
    }
  }
}
