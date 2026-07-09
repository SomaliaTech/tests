import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/common/entities/usecases.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/features/support/domain/repositories/faq_repository.dart';

class DeleteFaq implements UseCase<void, DeleteFaqParams> {
  final FaqRepository repository;

  DeleteFaq(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteFaqParams params) async {
    return await repository.deleteFaq(params.id);
  }
}

class DeleteFaqParams {
  final String id;
  const DeleteFaqParams({required this.id});
}
