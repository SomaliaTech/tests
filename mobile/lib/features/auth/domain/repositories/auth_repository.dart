import '../../../../core/utils/typedefs.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  ResultFuture<String> sendOtp(String phoneNumber);
  ResultFuture<({String token, User user})> verifyOtp(
    String phoneNumber,
    String otpCode,
  );
  ResultFuture<({String token, User user})> completeProfile({
    required String name,
    required String marketId,
    String? profileImageUrl,
  });
  ResultFuture<User> getCurrentUser();
  ResultFuture<String> uploadProfileImage(String base64Image);
  ResultFuture<bool> checkAuthStatus();
  ResultFuture<void> logout();
  // Add this method
  Future<bool>
  isAuthenticated(); // Note: not wrapped in ResultFuture because it's a local check
}
