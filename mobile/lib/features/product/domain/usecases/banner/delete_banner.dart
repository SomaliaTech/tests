import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/common/entities/usecases.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/features/product/domain/repositories/banner_repository.dart';

class DeleteBanner implements UseCase<void, DeleteBannerParams> {
  final BannerRepository repository;

  DeleteBanner(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteBannerParams params) async {
    return await repository.deleteBanner(params.id);
  }
}

class DeleteBannerParams {
  final String id;
  const DeleteBannerParams({required this.id});
}
