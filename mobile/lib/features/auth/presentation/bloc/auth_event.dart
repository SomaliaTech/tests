import 'package:equatable/equatable.dart';
// lib/features/auth/presentation/bloc/auth_event.dart

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
  final String marketId;
  final String? profileImageUrl;
  final String? phoneNumber;
  const CompleteProfileEvent({
    required this.name,
    required this.marketId,
    this.profileImageUrl,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [name, marketId, profileImageUrl, phoneNumber];
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

class GoogleSignInEvent extends AuthEvent {
  const GoogleSignInEvent();
}

class FacebookSignInEvent extends AuthEvent {
  final String accessToken;
  const FacebookSignInEvent(this.accessToken);

  @override
  List<Object?> get props => [accessToken];
}
