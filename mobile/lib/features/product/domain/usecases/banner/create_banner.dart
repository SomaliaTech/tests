import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/common/entities/usecases.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/features/product/domain/entities/banner.dart';
import 'package:mobile/features/product/domain/repositories/banner_repository.dart';

class CreateBanner implements UseCase<AppBanner, CreateBannerParams> {
  final BannerRepository repository;

  CreateBanner(this.repository);

  @override
  Future<Either<Failure, AppBanner>> call(CreateBannerParams params) async {
    return await repository.createBanner(params.bannerData);
  }
}

class CreateBannerParams {
  final Map<String, dynamic> bannerData;
  const CreateBannerParams({required this.bannerData});
}
