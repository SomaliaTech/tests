import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/error/failures.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/support_remote_data_source.dart';
import '../models/support_contact_model.dart';

class SupportRepositoryImpl implements SupportRepository {
  final SupportRemoteDataSource remote;
  SupportRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, SupportContact>> getContact() async {
    try {
      return Right(await remote.getContact());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, SupportContact>> updateContact({
    String? email,
    String? phoneNumber,
  }) async {
    try {
      return Right(
        await remote.updateContact(email: email, phoneNumber: phoneNumber),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
