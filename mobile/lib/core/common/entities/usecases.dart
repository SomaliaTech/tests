import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/error/failures.dart';

abstract interface class UseCase<SuccessType, Params> {
  Future<Either<Failure, SuccessType>> call(Params params);
}
