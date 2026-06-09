import '../../../../core/utils/typedefs.dart';
import '../repositories/auth_repository.dart';

class CheckAuthStatus {
  final AuthRepository repository;

  const CheckAuthStatus(this.repository);

  ResultFuture<bool> call() async {
    return await repository.checkAuthStatus();
  }
}
