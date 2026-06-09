// lib/features/auth/domain/usecases/upload_profile_image.dart
import '../../../../core/utils/typedefs.dart';
import '../repositories/auth_repository.dart';

class UploadProfileImage {
  final AuthRepository repository;
  const UploadProfileImage(this.repository);

  ResultFuture<String> call(String base64Image) async {
    return await repository.uploadProfileImage(base64Image);
  }
}
