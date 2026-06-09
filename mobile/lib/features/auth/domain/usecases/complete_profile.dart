// lib/features/auth/domain/usecases/complete_profile.dart
import '../../../../core/utils/typedefs.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class CompleteProfile {
  final AuthRepository repository;
  const CompleteProfile(this.repository);

  ResultFuture<({String token, User user})> call({
    required String name,
    String? email,
    String? profileImageUrl,
  }) async {
    return await repository.completeProfile(
      name: name,
      email: email,
      profileImageUrl: profileImageUrl,
    );
  }
}
