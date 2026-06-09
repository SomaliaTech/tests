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
  ResultFuture<String> sendOtp(String phoneNumber) async {
    try {
      final result = await remoteDataSource.sendOtp(phoneNumber);
      final debugOtp =
          result['debugOtp'] as String? ??
          result['message'] as String? ??
          'OTP sent';
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
      final data = await remoteDataSource.verifyOtp(phoneNumber, otpCode);
      final user = UserModel.fromJson(data['user']);
      final token = data['token'] as String;

      await storageService.saveAuthToken(token);
      await storageService.saveUserId(user.id);
      await storageService.saveLoginStatus(true);
      await storageService.saveUserPhone(user.phoneNumber);
      if (user.name != null) await storageService.saveUserName(user.name!);
      if (user.email != null) await storageService.saveUserEmail(user.email!);
      if (user.profileImage != null)
        await storageService.saveUserProfileImage(user.profileImage!);

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

      await storageService.saveAuthToken(newToken);
      await storageService.saveUserName(user.name ?? name);
      if (email != null) await storageService.saveUserEmail(email);
      if (profileImageUrl != null)
        await storageService.saveUserProfileImage(profileImageUrl);

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
      final user = UserModel.fromJson(data);

      await storageService.saveUserName(user.name ?? '');
      if (user.email != null) await storageService.saveUserEmail(user.email!);
      if (user.profileImage != null)
        await storageService.saveUserProfileImage(user.profileImage!);

      return Right(user);
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
