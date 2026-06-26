import 'package:equatable/equatable.dart';
import '../../domain/entities/profile.dart'; // ✅ Use correct entity

abstract class ProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Profile profile; // ✅ Use Profile
  ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileUpdated extends ProfileState {
  final Profile profile; // ✅ Use Profile
  ProfileUpdated(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProfileImageUploaded extends ProfileState {
  final String imageUrl;
  ProfileImageUploaded(this.imageUrl);

  @override
  List<Object?> get props => [imageUrl];
}

class AccountDeleted extends ProfileState {}
