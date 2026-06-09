// lib/features/auth/domain/usecases/logout.dart
import '../repositories/auth_repository.dart';

class Logout {
  final AuthRepository repository;
  const Logout(this.repository);

  Future<void> call() async {
    await repository.logout();
  }
}
