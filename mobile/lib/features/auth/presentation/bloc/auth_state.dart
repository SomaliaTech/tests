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

class OtpVerified extends AuthState {
  final String token;
  final User user;
  const OtpVerified(this.token, this.user);

  @override
  List<Object?> get props => [token, user];
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

class Authenticated extends AuthState {
  final User user;
  final String token;
  const Authenticated(this.user, this.token);

  @override
  List<Object?> get props => [user, token];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
