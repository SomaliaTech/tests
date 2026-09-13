// lib/features/profile/presentation/bloc/profile_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/profile/domain/usecases/delete_account.dart';
import 'package:mobile/features/profile/domain/usecases/get_profile.dart';
import 'package:mobile/features/profile/domain/usecases/update_profile.dart';
import 'package:mobile/features/auth/domain/usecases/upload_profile_image.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile getProfile;
  final UpdateProfile updateProfile;
  final UploadProfileImage uploadProfileImage;
  final DeleteAccount deleteAccount;
  final StorageService storageService;

  ProfileBloc({
    required this.getProfile,
    required this.updateProfile,
    required this.uploadProfileImage,
    required this.deleteAccount,
    required this.storageService,
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

    await result.fold(
      (failure) async {
        if (!emit.isDone) emit(ProfileError(failure.message));
      },
      (profile) async {
        await storageService.saveIsAdmin(profile.isAdmin);
        await storageService.saveIsSuperAdmin(profile.isSuperAdmin);
        if (!emit.isDone) emit(ProfileLoaded(profile));
      },
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

    await result.fold(
      (failure) async {
        if (!emit.isDone) emit(ProfileError(failure.message));
      },
      (updatedProfile) async {
        await storageService.saveIsAdmin(updatedProfile.isAdmin);
        await storageService.saveIsSuperAdmin(updatedProfile.isSuperAdmin);
        if (!emit.isDone) emit(ProfileUpdated(updatedProfile));
      },
    );
  }

  Future<void> _onUploadProfileImage(
    UploadProfileImageEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final result = await uploadProfileImage(event.base64Image);

    await result.fold(
      (failure) async {
        if (!emit.isDone) emit(ProfileError(failure.message));
      },
      (imageUrl) async {
        if (!emit.isDone) emit(ProfileImageUploaded(imageUrl));
        add(LoadProfileEvent());
      },
    );
  }

  // ✅ FIXED: await the fold, guard emits, no async-inside-sync-fold
  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    final result = await deleteAccount();

    await result.fold(
      (failure) async {
        if (!emit.isDone) emit(ProfileError(failure.message));
      },
      (_) async {
        await storageService.clearAuthData();
        if (!emit.isDone) emit(AccountDeleted());
      },
    );
  }
}
