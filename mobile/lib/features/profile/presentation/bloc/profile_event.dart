import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends ProfileEvent {}

class UpdateProfileEvent extends ProfileEvent {
  final String name;
  final String? email;
  final String? marketId; // ✅ Nullable

  UpdateProfileEvent({required this.name, this.email, this.marketId});

  @override
  List<Object?> get props => [name, email, marketId];
}

class UploadProfileImageEvent extends ProfileEvent {
  final String base64Image;

  UploadProfileImageEvent(this.base64Image);

  @override
  List<Object?> get props => [base64Image];
}

class DeleteAccountEvent extends ProfileEvent {}
