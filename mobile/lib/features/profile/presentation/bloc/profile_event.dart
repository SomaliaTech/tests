import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends ProfileEvent {}

class UpdateProfileEvent extends ProfileEvent {
  final String name;
  final String? email;
  final String? marketId;
  const UpdateProfileEvent({required this.name, this.email, this.marketId});
  @override
  List<Object?> get props => [name, email, marketId];
}

class UploadProfileImageEvent extends ProfileEvent {
  final String base64Image;
  const UploadProfileImageEvent(this.base64Image);
  @override
  List<Object?> get props => [base64Image];
}

class DeleteAccountEvent extends ProfileEvent {}
