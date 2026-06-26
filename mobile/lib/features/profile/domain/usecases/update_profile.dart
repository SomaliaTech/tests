import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

class UpdateProfile {
  final ProfileRepository repository;

  UpdateProfile(this.repository);

  Future<Either<Failure, Profile>> call({
    required String name,
    String? email,
    String? marketId, // ✅ Nullable
  }) async {
    return await repository.updateProfile(
      name: name,
      email: email,
      marketId: marketId,
    );
  }
}
