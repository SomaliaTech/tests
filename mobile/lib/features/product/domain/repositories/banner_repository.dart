import 'package:mobile/core/error/failures.dart';
import 'package:mobile/features/product/domain/entities/banner.dart';
import 'package:fpdart/fpdart.dart';

abstract class BannerRepository {
  // Public
  Future<Either<Failure, List<AppBanner>>> getActiveBanners();

  // Admin
  Future<Either<Failure, List<AppBanner>>> getAllBanners();
  Future<Either<Failure, AppBanner>> getBannerById(String id);
  Future<Either<Failure, AppBanner>> createBanner(
    Map<String, dynamic> bannerData,
  );
  Future<Either<Failure, AppBanner>> updateBanner(
    String id,
    Map<String, dynamic> bannerData,
  );
  Future<Either<Failure, void>> deleteBanner(String id);
  Future<Either<Failure, AppBanner>> toggleBannerStatus(String id);
  Future<Either<Failure, void>> reorderBanners(List<String> bannerIds);
}
