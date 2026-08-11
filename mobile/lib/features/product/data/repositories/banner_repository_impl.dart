// lib/features/product/data/repositories/banner_repository_impl.dart

import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/network/network_info.dart';
import 'package:mobile/features/product/domain/entities/banner.dart';
import 'package:mobile/features/product/domain/repositories/banner_repository.dart';
import 'package:mobile/features/product/data/datasources/banner_remote_data_source.dart';
import 'package:mobile/features/product/data/datasources/local/banner_local_data_source.dart';

class BannerRepositoryImpl implements BannerRepository {
  final BannerRemoteDataSource remoteDataSource;
  final BannerLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  BannerRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  // ==========================================
  // GET ACTIVE BANNERS (Offline-First)
  // ==========================================
  @override
  Future<Either<Failure, List<AppBanner>>> getActiveBanners() async {
    if (await networkInfo.isConnected) {
      try {
        final banners = await remoteDataSource.getActiveBanners();
        final entities = banners.map((b) => b.toEntity()).toList();
        // Cache for offline use
        await localDataSource.cacheActiveBanners(entities);
        return Right(entities);
      } on ServerException catch (e) {
        // Try cache on server error
        final cached = await localDataSource.getCachedActiveBanners();
        if (cached.isNotEmpty) return Right(cached);
        return Left(ServerFailure(e.message));
      } catch (e) {
        final cached = await localDataSource.getCachedActiveBanners();
        if (cached.isNotEmpty) return Right(cached);
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // Offline: return cached data
      final cached = await localDataSource.getCachedActiveBanners();
      if (cached.isNotEmpty) return Right(cached);
      return Left(NetworkFailure('No internet connection'));
    }
  }

  // ==========================================
  // GET ALL BANNERS (Online only - Admin)
  // ==========================================
  @override
  Future<Either<Failure, List<AppBanner>>> getAllBanners() async {
    if (await networkInfo.isConnected) {
      try {
        final banners = await remoteDataSource.getAllBanners();
        return Right(banners.map((b) => b.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // Try cached active banners as fallback
      final cached = await localDataSource.getCachedActiveBanners();
      if (cached.isNotEmpty) return Right(cached);
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, AppBanner>> getBannerById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final banner = await remoteDataSource.getBannerById(id);
        return Right(banner.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, AppBanner>> createBanner(
    Map<String, dynamic> bannerData,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }
    try {
      final banner = await remoteDataSource.createBanner(bannerData);
      return Right(banner.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppBanner>> updateBanner(
    String id,
    Map<String, dynamic> bannerData,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }
    try {
      final banner = await remoteDataSource.updateBanner(id, bannerData);
      return Right(banner.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBanner(String id) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }
    try {
      await remoteDataSource.deleteBanner(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppBanner>> toggleBannerStatus(String id) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }
    try {
      final banner = await remoteDataSource.toggleBannerStatus(id);
      return Right(banner.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reorderBanners(List<String> bannerIds) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }
    try {
      await remoteDataSource.reorderBanners(bannerIds);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
