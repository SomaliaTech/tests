import '../../../../core/utils/typedefs.dart';
import '../repositories/profile_repository.dart';

class DeleteAccount {
  final ProfileRepository repository;

  const DeleteAccount(this.repository);

  ResultFuture<void> call() async {
    return await repository.deleteAccount();
  }
}
