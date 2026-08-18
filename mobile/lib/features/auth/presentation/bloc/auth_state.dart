import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthChecking extends AuthState {}

// Change OtpSent to not include debugOtp
class OtpSent extends AuthState {
  final String message;

  const OtpSent(this.message);

  @override
  List<Object?> get props => [message];
}

class Authenticated extends AuthState {
  final User user;
  final String token;
  const Authenticated(this.user, this.token);

  @override
  List<Object?> get props => [user, token];
}

// In auth_state.dart - Add a timestamp to make each state unique
// auth_state.dart
class OtpVerified extends AuthState {
  final String token;
  final User user;
  final bool isGoogleSignIn; // ✅ Add this
  final DateTime timestamp;

  OtpVerified(
    this.token,
    this.user, {
    this.isGoogleSignIn = false, // ✅ Default to false for OTP users
  }) : timestamp = DateTime.now();

  @override
  List<Object?> get props => [token, user, isGoogleSignIn, timestamp];
}

class ProfileCompleted extends AuthState {
  final String token;
  final User user;
  const ProfileCompleted(this.token, this.user);

  @override
  List<Object?> get props => [token, user];
}

class ProfileImageUploaded extends AuthState {
  final String imageUrl;
  const ProfileImageUploaded(this.imageUrl);

  @override
  List<Object?> get props => [imageUrl];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// Add to auth_state.dart
class GoogleSignInSuccess extends AuthState {
  final String token;
  final User user;
  const GoogleSignInSuccess(this.token, this.user);

  @override
  List<Object?> get props => [token, user];
}
