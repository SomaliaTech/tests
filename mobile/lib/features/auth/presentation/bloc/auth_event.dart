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

// lib/features/auth/presentation/bloc/auth_event.dart
class CompleteProfileEvent extends AuthEvent {
  final String name;
  final String? email;
  final String marketId;
  final String? profileImageUrl;
  final String? phoneNumber; // ✅ Add phone number

  const CompleteProfileEvent({
    required this.name,
    this.email,
    required this.marketId,
    this.profileImageUrl,
    this.phoneNumber, // ✅ Add phone number
  });
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

// Add to auth_event.dart
// auth_event.dart
class GoogleSignInEvent extends AuthEvent {
  const GoogleSignInEvent();
}
