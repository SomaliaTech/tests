import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/auth/domain/usecases/upload_profile_image.dart';
import 'package:mobile/features/profile/domain/usecases/delete_account.dart';
import 'package:mobile/features/profile/domain/usecases/get_profile.dart';
import 'package:mobile/features/profile/domain/usecases/update_profile.dart';

import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile getProfile;
  final UpdateProfile updateProfile;
  final UploadProfileImage uploadProfileImage;
  final DeleteAccount deleteAccount;

  ProfileBloc({
    required this.getProfile,
    required this.updateProfile,
    required this.uploadProfileImage,
    required this.deleteAccount,
  }) : super(ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UploadProfileImageEvent>(_onUploadProfileImage);
    on<DeleteAccountEvent>(_onDeleteAccount);
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await getProfile();
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (profile) => emit(ProfileLoaded(profile)),
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await updateProfile(
      name: event.name,
      email: event.email,
      marketId: event.marketId,
    );
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (profile) => emit(ProfileUpdated(profile)),
    );
  }

  Future<void> _onUploadProfileImage(
    UploadProfileImageEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await uploadProfileImage(event.base64Image);
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (imageUrl) => emit(ProfileImageUploaded(imageUrl)),
    );
  }

  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await deleteAccount();
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (_) => emit(AccountDeleted()),
    );
  }
}
