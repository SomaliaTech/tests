import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/common/entities/usecases.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/features/support/domain/entities/faq.dart';
import 'package:mobile/features/support/domain/repositories/faq_repository.dart';

class ToggleFaqStatus implements UseCase<Faq, ToggleFaqStatusParams> {
  final FaqRepository repository;

  ToggleFaqStatus(this.repository);

  @override
  Future<Either<Failure, Faq>> call(ToggleFaqStatusParams params) async {
    return await repository.toggleFaqStatus(params.id);
  }
}

class ToggleFaqStatusParams {
  final String id;
  const ToggleFaqStatusParams({required this.id});
}
