// lib/features/auth/domain/repositories/auth_repository.dart
import '../../../../core/utils/typedefs.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  ResultFuture<String> sendOtp(String phoneNumber);
  ResultFuture<({String token, User user})> verifyOtp(
    String phoneNumber,
    String otpCode,
  );

  // ✅ Add phoneNumber parameter
  ResultFuture<({String token, User user})> completeProfile({
    required String name,
    required String marketId,
    String? profileImageUrl,
    String? phoneNumber, // ✅ Add this
  });

  ResultFuture<User> getCurrentUser();
  ResultFuture<String> uploadProfileImage(String base64Image);
  ResultFuture<bool> checkAuthStatus();
  ResultFuture<void> logout();
  Future<bool> isAuthenticated();
  ResultFuture<({String token, User user})> googleSignIn(String idToken);
  ResultFuture<({String token, User user})> facebookSignIn(String accessToken);
}
