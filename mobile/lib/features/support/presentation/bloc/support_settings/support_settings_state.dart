import 'package:equatable/equatable.dart';
import '../../../data/models/support_contact_model.dart';

abstract class SupportSettingsState extends Equatable {
  const SupportSettingsState();
  @override
  List<Object?> get props => [];
}

class SupportSettingsInitial extends SupportSettingsState {}

class SupportSettingsLoading extends SupportSettingsState {}

class SupportSettingsLoaded extends SupportSettingsState {
  final SupportContact contact;
  const SupportSettingsLoaded(this.contact);
  @override
  List<Object?> get props => [contact];
}

class SupportSettingsSaving extends SupportSettingsState {
  const SupportSettingsSaving();
}

class SupportSettingsSaved extends SupportSettingsState {
  final String message;
  final SupportContact contact;
  const SupportSettingsSaved(this.message, this.contact);
  @override
  List<Object?> get props => [message, contact];
}

class SupportSettingsError extends SupportSettingsState {
  final String message;
  const SupportSettingsError(this.message);
  @override
  List<Object?> get props => [message];
}
