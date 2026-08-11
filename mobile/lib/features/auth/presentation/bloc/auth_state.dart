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

class OtpSent extends AuthState {
  final String debugOtp;
  const OtpSent(this.debugOtp);

  @override
  List<Object?> get props => [debugOtp];
}

class Authenticated extends AuthState {
  final User user;
  final String token;
  const Authenticated(this.user, this.token);

  @override
  List<Object?> get props => [user, token];
}

// In auth_state.dart - Add a timestamp to make each state unique
class OtpVerified extends AuthState {
  final String token;
  final User user;
  final DateTime timestamp; // ✅ Add this to make each emit unique

  OtpVerified(this.token, this.user)
    : timestamp = DateTime.now(); // Auto-set timestamp

  @override
  List<Object?> get props => [token, user, timestamp]; // Include timestamp
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
