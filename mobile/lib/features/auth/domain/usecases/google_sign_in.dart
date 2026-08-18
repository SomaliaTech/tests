// google_sign_in.dart
import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/core/utils/typedefs.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';

class GoogleSignIn {
  final AuthRepository repository;

  GoogleSignIn(this.repository);

  // ✅ Only pass ID token
  ResultFuture<({String token, User user})> call(String idToken) {
    return repository.googleSignIn(idToken);
  }
}
