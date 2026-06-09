import '../../../../core/utils/typedefs.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  final ProfileRepository repository;

  const GetProfile(this.repository);

  ResultFuture<Profile> call() async {
    return await repository.getProfile();
  }
}
