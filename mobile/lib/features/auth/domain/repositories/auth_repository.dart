// lib/features/auth/domain/repositories/auth_repository.dart
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
    String? email,
    String? profileImageUrl,
  });
  ResultFuture<User> getCurrentUser();
  ResultFuture<String> uploadProfileImage(String base64Image);
  Future<void> logout();
  Future<bool> isAuthenticated();
}
