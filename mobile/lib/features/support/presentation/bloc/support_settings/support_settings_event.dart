import 'package:equatable/equatable.dart';

abstract class SupportSettingsEvent extends Equatable {
  const SupportSettingsEvent();
  @override
  List<Object?> get props => [];
}

class LoadSupportSettingsEvent extends SupportSettingsEvent {
  const LoadSupportSettingsEvent();
}

class SaveSupportSettingsEvent extends SupportSettingsEvent {
  final String? email;
  final String? phoneNumber;
  const SaveSupportSettingsEvent({this.email, this.phoneNumber});
  @override
  List<Object?> get props => [email, phoneNumber];
}
