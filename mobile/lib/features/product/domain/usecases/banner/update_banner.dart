import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/common/entities/usecases.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/features/product/domain/entities/banner.dart';
import 'package:mobile/features/product/domain/repositories/banner_repository.dart';

class UpdateBanner implements UseCase<AppBanner, UpdateBannerParams> {
  final BannerRepository repository;

  UpdateBanner(this.repository);

  @override
  Future<Either<Failure, AppBanner>> call(UpdateBannerParams params) async {
    return await repository.updateBanner(params.id, params.bannerData);
  }
}

class UpdateBannerParams {
  final String id;
  final Map<String, dynamic> bannerData;
  const UpdateBannerParams({required this.id, required this.bannerData});
}
