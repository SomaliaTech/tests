// lib/features/auth/domain/usecases/google_sign_in.dart
import 'package:mobile/core/utils/typedefs.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GoogleSignIn {
  final AuthRepository repository;

  GoogleSignIn(this.repository);

  ResultFuture<({String token, User user})> call(
    String idToken,
    String email,
    String name,
    String? photoUrl,
  ) {
    return repository.googleSignIn(idToken, email, name, photoUrl);
  }
}
