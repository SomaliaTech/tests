import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/common/entities/usecases.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/features/product/domain/entities/banner.dart';
import 'package:mobile/features/product/domain/repositories/banner_repository.dart';

class ToggleBannerStatus implements UseCase<AppBanner, ToggleBannerParams> {
  final BannerRepository repository;

  ToggleBannerStatus(this.repository);

  @override
  Future<Either<Failure, AppBanner>> call(ToggleBannerParams params) async {
    return await repository.toggleBannerStatus(params.id);
  }
}

class ToggleBannerParams {
  final String id;
  const ToggleBannerParams({required this.id});
}
