import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/common/entities/no_params.dart';
import 'package:mobile/core/common/entities/usecases.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/features/support/domain/entities/faq.dart';
import 'package:mobile/features/support/domain/repositories/faq_repository.dart';

class GetAllFaqs implements UseCase<List<Faq>, NoParams> {
  final FaqRepository repository;

  GetAllFaqs(this.repository);

  @override
  Future<Either<Failure, List<Faq>>> call(NoParams params) async {
    return await repository.getAllFaqs();
  }
}
