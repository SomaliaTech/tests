import '../../../../core/utils/typedefs.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class UpdateProfile {
  final ProfileRepository repository;

  const UpdateProfile(this.repository);

  ResultFuture<Profile> call({
    required String name,
    String? email,
    String? marketId,
  }) async {
    return await repository.updateProfile(
      name: name,
      email: email,
      marketId: marketId,
    );
  }
}
