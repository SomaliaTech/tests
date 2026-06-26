import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SendOtpEvent extends AuthEvent {
  final String phoneNumber;
  const SendOtpEvent(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class VerifyOtpEvent extends AuthEvent {
  final String phoneNumber;
  final String otpCode;
  const VerifyOtpEvent(this.phoneNumber, this.otpCode);

  @override
  List<Object?> get props => [phoneNumber, otpCode];
}

class CompleteProfileEvent extends AuthEvent {
  final String name;
  final String email; // ✅ Changed from String? to String (required)
  final String marketId; // ✅ Added marketId
  final String? profileImageUrl;

  const CompleteProfileEvent({
    required this.name,
    required this.email, // ✅ Now required
    required this.marketId, // ✅ Required
    this.profileImageUrl,
  });

  @override
  List<Object?> get props => [name, email, marketId, profileImageUrl];
}

class UploadProfileImageEvent extends AuthEvent {
  final String base64Image;
  const UploadProfileImageEvent(this.base64Image);

  @override
  List<Object?> get props => [base64Image];
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}
