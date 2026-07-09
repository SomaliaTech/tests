import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/common/entities/usecases.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/features/support/domain/entities/faq.dart';
import 'package:mobile/features/support/domain/repositories/faq_repository.dart';

class CreateFaq implements UseCase<Faq, CreateFaqParams> {
  final FaqRepository repository;

  CreateFaq(this.repository);

  @override
  Future<Either<Failure, Faq>> call(CreateFaqParams params) async {
    return await repository.createFaq(params.faqData);
  }
}

class CreateFaqParams {
  final Map<String, dynamic> faqData;
  const CreateFaqParams({required this.faqData});
}
