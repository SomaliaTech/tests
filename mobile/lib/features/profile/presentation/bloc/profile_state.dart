import 'package:equatable/equatable.dart';
import '../../domain/entities/profile.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Profile profile;
  const ProfileLoaded(this.profile);
  @override
  List<Object?> get props => [profile];
}

class ProfileImageUploaded extends ProfileState {
  final String imageUrl;
  const ProfileImageUploaded(this.imageUrl);
  @override
  List<Object?> get props => [imageUrl];
}

class ProfileUpdated extends ProfileState {
  final Profile profile;
  const ProfileUpdated(this.profile);
  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

class AccountDeleted extends ProfileState {}
