import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/error/failures.dart';
import '../../data/models/support_contact_model.dart';

abstract class SupportRepository {
  Future<Either<Failure, SupportContact>> getContact();
  Future<Either<Failure, SupportContact>> updateContact({
    String? email,
    String? phoneNumber,
  });
}
