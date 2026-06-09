// lib/features/auth/domain/usecases/get_current_user.dart
import '../../../../core/utils/typedefs.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUser {
  final AuthRepository repository;
  const GetCurrentUser(this.repository);

  ResultFuture<User> call() async {
    return await repository.getCurrentUser();
  }
}
