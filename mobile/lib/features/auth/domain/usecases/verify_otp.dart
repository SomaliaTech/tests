// lib/features/auth/domain/usecases/verify_otp.dart
import '../../../../core/utils/typedefs.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class VerifyOtp {
  final AuthRepository repository;
  const VerifyOtp(this.repository);

  ResultFuture<({String token, User user})> call(
    String phoneNumber,
    String otpCode,
  ) async {
    return await repository.verifyOtp(phoneNumber, otpCode);
  }
}
