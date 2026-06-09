import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final StorageService storageService;

  const ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  @override
  ResultFuture<Profile> getProfile() async {
    try {
      final token = await storageService.getAuthToken();
      if (token == null) {
        return Left(ServerFailure('No authentication token found'));
      }

      final data = await remoteDataSource.getProfile(token);
      final profile = ProfileModel.fromJson(data);

      // Update local storage
      await storageService.saveUserName(profile.name);
      await storageService.saveUserEmail(profile.email ?? '');
      await storageService.saveUserProfileImage(profile.profileImage ?? '');
      if (profile.marketId != null) {
        await storageService.saveUserMarketId(profile.marketId!);
      }

      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<Profile> updateProfile({
    required String name,
    String? email,
    String? marketId,
  }) async {
    try {
      final token = await storageService.getAuthToken();
      if (token == null) {
        return Left(ServerFailure('No authentication token found'));
      }

      final data = await remoteDataSource.updateProfile(
        token,
        name,
        email,
        marketId,
      );
      final profile = ProfileModel.fromJson(data);

      // Update local storage
      await storageService.saveUserName(profile.name);
      if (email != null) await storageService.saveUserEmail(email);
      if (marketId != null) await storageService.saveUserMarketId(marketId);

      return Right(profile);
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

      await storageService.saveUserProfileImage(imageUrl);

      return Right(imageUrl);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<void> deleteAccount() async {
    try {
      final token = await storageService.getAuthToken();
      if (token == null) {
        return Left(ServerFailure('No authentication token found'));
      }

      await remoteDataSource.deleteAccount(token);
      await storageService.clearAuthData();

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
