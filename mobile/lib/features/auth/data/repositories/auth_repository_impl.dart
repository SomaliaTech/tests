// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final StorageService storageService;

  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  @override
  ResultFuture<String> sendOtp(String phoneNumber) async {
    try {
      final result = await remoteDataSource.sendOtp(phoneNumber);
      final debugOtp = result['debugOtp'] as String? ?? '';
      return Right(debugOtp);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<({String token, User user})> verifyOtp(
    String phoneNumber,
    String otpCode,
  ) async {
    try {
      // Direct string representation verification pass-through
      final cleanPhoneString = phoneNumber.toString();

      final data = await remoteDataSource.verifyOtp(cleanPhoneString, otpCode);
      final user = UserModel.fromJson(data['user']);
      final token = data['token'] as String;

      // Save complete normalized auth payload locally
      await storageService.saveAuthToken(token);
      await storageService.saveUserId(user.id);
      await storageService.savePhoneNumber(cleanPhoneString);

      return Right((token: token, user: user));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<({String token, User user})> completeProfile({
    required String name,
    String? email,
    String? profileImageUrl,
  }) async {
    try {
      final token = await storageService.getAuthToken();
      if (token == null) {
        return Left(ServerFailure('No authentication token found'));
      }

      final data = await remoteDataSource.completeProfile(
        token,
        name,
        email,
        profileImageUrl,
      );

      final user = UserModel.fromJson(data['user']);
      final newToken = data['token'] as String;

      if (newToken != token) {
        await storageService.saveAuthToken(newToken);
      }

      return Right((token: newToken, user: user));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<User> getCurrentUser() async {
    try {
      final token = await storageService.getAuthToken();
      if (token == null) {
        return Left(ServerFailure('No authentication token found'));
      }

      final data = await remoteDataSource.getCurrentUser(token);
      return Right(UserModel.fromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<String> uploadProfileImage(String base64Image) async {
    try {
      final token = await storageService.getAuthToken();
      if (token == null) {
        return Left(ServerFailure('No authentication token found'));
      }

      final data = await remoteDataSource.uploadProfileImage(
        token,
        base64Image,
      );
      final profileImage = data['profileImage'] as String;
      return Right(profileImage);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<void> logout() async {
    await storageService.clearAuthData();
  }

  @override
  Future<bool> isAuthenticated() async {
    return await storageService.isAuthenticated();
  }
}
