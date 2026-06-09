import '../../../../core/utils/typedefs.dart';
import '../entities/profile.dart';

abstract class ProfileRepository {
  ResultFuture<Profile> getProfile();
  ResultFuture<Profile> updateProfile({
    required String name,
    String? email,
    String? marketId,
  });
  ResultFuture<String> uploadProfileImage(String base64Image);
  ResultFuture<void> deleteAccount();
}
