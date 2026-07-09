import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/common/entities/usecases.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/features/support/domain/entities/faq.dart';
import 'package:mobile/features/support/domain/repositories/faq_repository.dart';

class UpdateFaq implements UseCase<Faq, UpdateFaqParams> {
  final FaqRepository repository;

  UpdateFaq(this.repository);

  @override
  Future<Either<Failure, Faq>> call(UpdateFaqParams params) async {
    return await repository.updateFaq(params.id, params.faqData);
  }
}

class UpdateFaqParams {
  final String id;
  final Map<String, dynamic> faqData;
  const UpdateFaqParams({required this.id, required this.faqData});
}
