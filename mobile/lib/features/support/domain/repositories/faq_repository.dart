import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/features/support/domain/entities/faq.dart';

abstract class FaqRepository {
  Future<Either<Failure, List<Faq>>> getActiveFaqs();
  Future<Either<Failure, List<Faq>>> getAllFaqs();
  Future<Either<Failure, Faq>> getFaqById(String id);
  Future<Either<Failure, Faq>> createFaq(Map<String, dynamic> faqData);
  Future<Either<Failure, Faq>> updateFaq(
    String id,
    Map<String, dynamic> faqData,
  );
  Future<Either<Failure, void>> deleteFaq(String id);
  Future<Either<Failure, Faq>> toggleFaqStatus(String id);
  Future<Either<Failure, void>> reorderFaqs(List<String> faqIds);
}
