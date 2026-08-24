import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class FacebookSignIn {
  final AuthRepository repository;

  FacebookSignIn(this.repository);

  Future<Either<Failure, ({String token, User user})>> call(
    String accessToken,
  ) async {
    return await repository.facebookSignIn(accessToken);
  }
}
