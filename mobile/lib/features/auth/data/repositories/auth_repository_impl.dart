import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';
import 'dart:developer' as developer;

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final StorageService storageService;

  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  @override
  ResultFuture<bool> checkAuthStatus() async {
    try {
      final token = await storageService.getAuthToken();
      final isLoggedIn = await storageService.isAuthenticated();
      return Right(token != null && token.isNotEmpty && isLoggedIn);
    } catch (e) {
      return Left(ServerFailure('Failed to check auth status: $e'));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await storageService.isAuthenticated();
    } catch (e) {
      return false;
    }
  }

  @override
  ResultFuture<void> logout() async {
    try {
      await storageService.clearAuthData();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to logout: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> sendOtp(String phoneNumber) async {
    try {
      developer.log('📞 Sending OTP to: $phoneNumber');
      final result = await remoteDataSource.sendOtp(phoneNumber);
      developer.log('✅ OTP Response: $result');

      final debugOtp = result['debugOtp'] ?? result['otp'] ?? '123456';
      developer.log(' Debug OTP: $debugOtp');

      return Right(debugOtp);
    } on ServerException catch (e) {
      developer.log('❌ OTP Error: $e');
      return Left(ServerFailure(e.message));
    }
  }

  @override
  ResultFuture<({String token, User user})> verifyOtp(
    String phoneNumber,
    String otpCode,
  ) async {
    try {
      final data = await remoteDataSource.verifyOtp(phoneNumber, otpCode);
      final user = UserModel.fromJson(data['user']);
      final token = data['token'] as String;

      await storageService.saveAuthToken(token);
      await storageService.saveUserId(user.id);
      await storageService.saveLoginStatus(true);

      // ✅ Fix: Handle nullable bool with null safety
      await storageService.saveIsAdmin(user.isAdmin ?? false);
      await storageService.saveIsSuperAdmin(user.isSuperAdmin ?? false);

      await storageService.saveUserPhone(user.phoneNumber);

      if (user.name != null) {
        await storageService.saveUserName(user.name!);
      }

      if (user.profileImage != null) {
        await storageService.saveUserProfileImage(user.profileImage!);
      }

      developer.log(
        '👑 VerifyOTP - Saved isAdmin: ${user.isAdmin ?? false}, isSuperAdmin: ${user.isSuperAdmin ?? false}',
      );

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
    required String marketId,
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
        marketId,
        profileImageUrl,
      );
      final user = UserModel.fromJson(data['user']);
      final newToken = data['token'] as String;

      await storageService.saveAuthToken(newToken);

      // ✅ Fix: Handle nullable bool with null safety
      await storageService.saveIsAdmin(user.isAdmin ?? false);
      await storageService.saveIsSuperAdmin(user.isSuperAdmin ?? false);

      await storageService.saveUserName(user.name ?? name);
      await storageService.saveUserMarketId(marketId);

      if (profileImageUrl != null) {
        await storageService.saveUserProfileImage(profileImageUrl);
      }

      developer.log(
        '👑 CompleteProfile - Saved isAdmin: ${user.isAdmin ?? false}, isSuperAdmin: ${user.isSuperAdmin ?? false}',
      );

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
        return Left(UnauthorizedFailure('No authentication token found'));
      }

      final data = await remoteDataSource.getCurrentUser(token);
      final user = UserModel.fromJson(data);

      // Save to local storage for offline access
      await storageService.saveUserName(user.name ?? '');

      // ✅ Fix: Handle nullable bool with null safety
      await storageService.saveIsAdmin(user.isAdmin ?? false);
      await storageService.saveIsSuperAdmin(user.isSuperAdmin ?? false);

      if (user.profileImage != null) {
        await storageService.saveUserProfileImage(user.profileImage!);
      }

      developer.log(
        '👑 GetCurrentUser - isAdmin: ${user.isAdmin ?? false}, isSuperAdmin: ${user.isSuperAdmin ?? false}',
      );

      return Right(user);
    } on UnauthorizedException catch (e) {
      // 🚨 Token is actually invalid. Clear local storage.
      await storageService.clearAuthData();
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      // 🚨 Network error or 500. DO NOT clear local storage.
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

      final result = await remoteDataSource.uploadProfileImage(
        token,
        base64Image,
      );
      final imageUrl = result['profileImage'] as String? ?? '';
      if (imageUrl.isNotEmpty) {
        await storageService.saveUserProfileImage(imageUrl);
      }
      return Right(imageUrl);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
