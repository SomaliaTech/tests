import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/auth/domain/usecases/complete_profile.dart';
import '../../domain/usecases/check_auth_status.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/send_otp.dart';
import '../../domain/usecases/upload_profile_image.dart';
import '../../domain/usecases/verify_otp.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'dart:developer' as developer;

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendOtp sendOtp;
  final VerifyOtp verifyOtp;
  final CompleteProfile completeProfile;
  final UploadProfileImage uploadProfileImage;
  final GetCurrentUser getCurrentUser;
  final CheckAuthStatus checkAuthStatus;
  final Logout logout;

  AuthBloc({
    required this.sendOtp,
    required this.verifyOtp,
    required this.completeProfile,
    required this.uploadProfileImage,
    required this.getCurrentUser,
    required this.checkAuthStatus,
    required this.logout,
  }) : super(AuthInitial()) {
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<CompleteProfileEvent>(_onCompleteProfile);
    on<UploadProfileImageEvent>(_onUploadProfileImage);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LogoutEvent>(_onLogout);
  }

  // Future<void> _onSendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {
  //   emit(AuthLoading());
  //   final result = await sendOtp(event.phoneNumber);
  //   result.fold(
  //     (failure) => emit(AuthError(failure.message)),
  //     (debugOtp) => emit(OtpSent(debugOtp)),
  //   );
  // }

  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await verifyOtp(event.phoneNumber, event.otpCode);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (data) => emit(OtpVerified(data.token, data.user)),
    );
  }

  Future<void> _onSendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {
    developer.log('📞 Sending OTP for: ${event.phoneNumber}');
    emit(AuthLoading());

    try {
      final result = await sendOtp(event.phoneNumber);
      developer.log('📦 OTP Result: $result');

      result.fold(
        (failure) {
          developer.log('❌ OTP Failure: ${failure.message}');
          emit(AuthError(failure.message));
        },
        (debugOtp) {
          developer.log('✅ OTP Sent Successfully: $debugOtp');
          emit(OtpSent(debugOtp));
        },
      );
    } catch (e) {
      developer.log('❌ OTP Exception: $e');
      emit(AuthError('An unexpected error occurred: $e'));
    }
  }

  Future<void> _onCompleteProfile(
    CompleteProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await completeProfile(
      name: event.name,
      profileImageUrl: event.profileImageUrl,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (data) => emit(ProfileCompleted(data.token, data.user)),
    );
  }

  Future<void> _onUploadProfileImage(
    UploadProfileImageEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await uploadProfileImage(event.base64Image);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (imageUrl) => emit(ProfileImageUploaded(imageUrl)),
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthChecking());

    final result = await checkAuthStatus();

    // Use fold to unwrap the Either value from the usecase result
    await result.fold(
      (failure) async {
        // If checking auth failed structurally, treat it as unauthenticated
        emit(Unauthenticated());
      },
      (isAuthenticated) async {
        if (isAuthenticated) {
          // Get current user details
          final userResult = await getCurrentUser();

          await userResult.fold(
            (failure) async {
              // Token might be invalid/expired, clear and show unauthenticated
              await logout.call();
              emit(Unauthenticated());
            },
            (user) async {
              // Get token from storage
              final token = await getCurrentToken();
              emit(Authenticated(user, token ?? ''));
            },
          );
        } else {
          emit(Unauthenticated());
        }
      },
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await logout.call();
    emit(Unauthenticated());
  }

  Future<String?> getCurrentToken() async {
    // This would need access to storage service
    // For now, we'll handle it in the repository
    return null;
  }
}
