// lib/features/auth/domain/usecases/send_otp.dart
import '../../../../core/utils/typedefs.dart';
import '../repositories/auth_repository.dart';

class SendOtp {
  final AuthRepository repository;
  const SendOtp(this.repository);

  ResultFuture<String> call(String phoneNumber) async {
    return await repository.sendOtp(phoneNumber);
  }
}
