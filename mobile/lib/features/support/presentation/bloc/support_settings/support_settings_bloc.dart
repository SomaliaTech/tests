import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/support/domain/repositories/support_repository.dart';
import 'support_settings_event.dart';
import 'support_settings_state.dart';

class SupportSettingsBloc
    extends Bloc<SupportSettingsEvent, SupportSettingsState> {
  final SupportRepository repository;

  SupportSettingsBloc({required this.repository})
    : super(SupportSettingsInitial()) {
    on<LoadSupportSettingsEvent>(_onLoad);
    on<SaveSupportSettingsEvent>(_onSave);
  }

  Future<void> _onLoad(
    LoadSupportSettingsEvent event,
    Emitter<SupportSettingsState> emit,
  ) async {
    emit(SupportSettingsLoading());
    final result = await repository.getContact();
    result.fold(
      (f) => emit(SupportSettingsError(f.message)),
      (contact) => emit(SupportSettingsLoaded(contact)),
    );
  }

  Future<void> _onSave(
    SaveSupportSettingsEvent event,
    Emitter<SupportSettingsState> emit,
  ) async {
    emit(const SupportSettingsSaving());
    final result = await repository.updateContact(
      email: event.email,
      phoneNumber: event.phoneNumber,
    );
    result.fold(
      (f) => emit(SupportSettingsError(f.message)),
      (contact) =>
          emit(SupportSettingsSaved('Support contact updated', contact)),
    );
  }
}
