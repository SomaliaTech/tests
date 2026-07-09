import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/support/domain/entities/faq.dart';
import 'package:mobile/features/support/domain/repositories/faq_repository.dart';
import 'package:mobile/features/support/data/datasources/faq_remote_data_source.dart';

class FaqRepositoryImpl implements FaqRepository {
  final FaqRemoteDataSource remoteDataSource;

  FaqRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Faq>>> getActiveFaqs() async {
    try {
      final faqs = await remoteDataSource.getActiveFaqs();
      return Right(faqs.map((f) => f.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Faq>>> getAllFaqs() async {
    try {
      final faqs = await remoteDataSource.getAllFaqs();
      return Right(faqs.map((f) => f.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Faq>> getFaqById(String id) async {
    try {
      final faq = await remoteDataSource.getFaqById(id);
      return Right(faq.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Faq>> createFaq(Map<String, dynamic> faqData) async {
    try {
      final faq = await remoteDataSource.createFaq(faqData);
      return Right(faq.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Faq>> updateFaq(
    String id,
    Map<String, dynamic> faqData,
  ) async {
    try {
      final faq = await remoteDataSource.updateFaq(id, faqData);
      return Right(faq.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFaq(String id) async {
    try {
      await remoteDataSource.deleteFaq(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Faq>> toggleFaqStatus(String id) async {
    try {
      final faq = await remoteDataSource.toggleFaqStatus(id);
      return Right(faq.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> reorderFaqs(List<String> faqIds) async {
    try {
      await remoteDataSource.reorderFaqs(faqIds);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
