import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/common/entities/usecases.dart';
import 'package:mobile/core/common/entities/no_params.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/features/product/domain/entities/banner.dart';
import 'package:mobile/features/product/domain/repositories/banner_repository.dart';

class GetActiveBanners implements UseCase<List<AppBanner>, NoParams> {
  final BannerRepository repository;

  GetActiveBanners(this.repository);

  @override
  Future<Either<Failure, List<AppBanner>>> call(NoParams params) async {
    return await repository.getActiveBanners();
  }
}
