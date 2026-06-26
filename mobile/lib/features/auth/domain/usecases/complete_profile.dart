import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class CompleteProfile {
  final AuthRepository repository;

  CompleteProfile(this.repository);

  ResultFuture<({String token, User user})> call({
    required String name,
    required String email, // ✅ Now required
    required String marketId, // ✅ Added
    String? profileImageUrl,
  }) async {
    return await repository.completeProfile(
      name: name,
      email: email,
      marketId: marketId,
      profileImageUrl: profileImageUrl,
    );
  }
}
