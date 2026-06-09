import '../../../../core/utils/typedefs.dart';
import '../repositories/profile_repository.dart';

class UploadProfileImage {
  final ProfileRepository repository;

  const UploadProfileImage(this.repository);

  ResultFuture<String> call(String base64Image) async {
    return await repository.uploadProfileImage(base64Image);
  }
}
