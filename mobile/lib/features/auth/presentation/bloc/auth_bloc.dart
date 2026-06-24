// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:mobile/core/error/failures.dart';
// import 'package:mobile/core/services/storage/storage_service.dart';
// import 'package:mobile/features/auth/domain/usecases/complete_profile.dart';
// import '../../domain/usecases/check_auth_status.dart';
// import '../../domain/usecases/get_current_user.dart';
// import '../../domain/usecases/logout.dart';
// import '../../domain/usecases/send_otp.dart';
// import '../../domain/usecases/upload_profile_image.dart';
// import '../../domain/usecases/verify_otp.dart';
// import 'auth_event.dart';
// import 'auth_state.dart';
// import 'dart:developer' as developer;
// import '../../domain/entities/user.dart';

// class AuthBloc extends Bloc<AuthEvent, AuthState> {
//   final SendOtp sendOtp;
//   final VerifyOtp verifyOtp;
//   final CompleteProfile completeProfile;
//   final UploadProfileImage uploadProfileImage;
//   final GetCurrentUser getCurrentUser;
//   final CheckAuthStatus checkAuthStatus;
//   final Logout logout;
//   final StorageService storageService;

//   AuthBloc({
//     required this.sendOtp,
//     required this.verifyOtp,
//     required this.completeProfile,
//     required this.uploadProfileImage,
//     required this.getCurrentUser,
//     required this.checkAuthStatus,
//     required this.logout,
//     required this.storageService,
//   }) : super(AuthInitial()) {
//     on<SendOtpEvent>(_onSendOtp);
//     on<VerifyOtpEvent>(_onVerifyOtp);
//     on<CompleteProfileEvent>(_onCompleteProfile);
//     on<UploadProfileImageEvent>(_onUploadProfileImage);
//     on<CheckAuthStatusEvent>(_onCheckAuthStatus);
//     on<LogoutEvent>(_onLogout);
//   }

//   Future<void> _onSendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {
//     developer.log('📞 Sending OTP for: ${event.phoneNumber}');
//     emit(AuthLoading());

//     try {
//       final result = await sendOtp(event.phoneNumber);
//       developer.log('📦 OTP Result: $result');

//       result.fold(
//         (failure) {
//           developer.log('❌ OTP Failure: ${failure.message}');
//           emit(AuthError(failure.message));
//         },
//         (debugOtp) {
//           developer.log('✅ OTP Sent Successfully: $debugOtp');
//           emit(OtpSent(debugOtp));
//         },
//       );
//     } catch (e) {
//       developer.log('❌ OTP Exception: $e');
//       emit(AuthError('An unexpected error occurred: $e'));
//     }
//   }

//   Future<void> _onVerifyOtp(
//     VerifyOtpEvent event,
//     Emitter<AuthState> emit,
//   ) async {
//     emit(AuthLoading());
//     final result = await verifyOtp(event.phoneNumber, event.otpCode);

//     // 🚨 CRITICAL FIX: Await the fold function so it waits for the async callbacks to finish
//     await result.fold(
//       (failure) async {
//         emit(AuthError(failure.message));
//       },
//       (data) async {
//         print(
//           '🔑 Saving token: ${data.token.length > 20 ? data.token.substring(0, 20) : data.token}...',
//         );

//         // 🚨 CRITICAL FIX: Await ALL storage writes to prevent race conditions!
//         await storageService.saveAuthToken(data.token);
//         await storageService.saveUserId(data.user.id);
//         await storageService.saveLoginStatus(true);
//         await storageService.saveUserName(data.user.name ?? '');
//         await storageService.saveUserPhone(data.user.phoneNumber);

//         if (data.user.email != null) {
//           await storageService.saveUserEmail(data.user.email!);
//         }
//         if (data.user.profileImage != null) {
//           await storageService.saveUserProfileImage(data.user.profileImage!);
//         }
//         await storageService.saveIsAdmin(data.user.isAdmin ?? false);

//         // Now that everything is safely saved to disk, emit the state and navigate
//         emit(OtpVerified(data.token, data.user));
//       },
//     );
//   }

//   Future<void> _onCompleteProfile(
//     CompleteProfileEvent event,
//     Emitter<AuthState> emit,
//   ) async {
//     emit(AuthLoading());
//     final result = await completeProfile(
//       name: event.name,
//       profileImageUrl: event.profileImageUrl,
//     );

//     // 🚨 CRITICAL FIX: Await the fold function
//     await result.fold(
//       (failure) async {
//         emit(AuthError(failure.message));
//       },
//       (data) async {
//         // 🚨 CRITICAL FIX: Await storage writes
//         await storageService.saveUserName(event.name);
//         if (event.profileImageUrl != null) {
//           await storageService.saveUserProfileImage(event.profileImageUrl!);
//         }
//         await storageService.saveLoginStatus(true);

//         emit(ProfileCompleted(data.token, data.user));
//       },
//     );
//   }

//   Future<void> _onUploadProfileImage(
//     UploadProfileImageEvent event,
//     Emitter<AuthState> emit,
//   ) async {
//     emit(AuthLoading());
//     final result = await uploadProfileImage(event.base64Image);

//     // 🚨 CRITICAL FIX: Await the fold function
//     await result.fold(
//       (failure) async {
//         emit(AuthError(failure.message));
//       },
//       (imageUrl) async {
//         // 🚨 CRITICAL FIX: Await storage write
//         await storageService.saveUserProfileImage(imageUrl);
//         emit(ProfileImageUploaded(imageUrl));
//       },
//     );
//   }

//   Future<void> _onCheckAuthStatus(
//     CheckAuthStatusEvent event,
//     Emitter<AuthState> emit,
//   ) async {
//     emit(AuthChecking());

//     // ✅ Check if authenticated using storageService
//     final isAuthenticated = await storageService.isAuthenticated();

//     if (!isAuthenticated) {
//       emit(Unauthenticated());
//       return;
//     }

//     // Get token
//     final token = await storageService.getAuthToken();
//     if (token == null || token.isEmpty) {
//       emit(Unauthenticated());
//       return;
//     }

//     // Get user from API
//     final userResult = await getCurrentUser();
//     await userResult.fold(
//       (failure) async {
//         // If API fails, load from local storage
//         final name = await storageService.getUserName() ?? 'User';
//         final phone = await storageService.getUserPhone() ?? '';
//         final email = await storageService.getUserEmail();
//         final profileImage = await storageService.getUserProfileImage();
//         final userId = await storageService.getUserId() ?? '';
//         final isAdmin = await storageService.getIsAdmin();

//         final localUser = User(
//           id: userId,
//           phoneNumber: phone,
//           name: name,
//           email: email,
//           profileImage: profileImage,
//           isVerified: true,
//           hasProfile: name.isNotEmpty,
//           isAdmin: isAdmin,
//         );

//         emit(Authenticated(localUser, token));
//       },
//       (user) async {
//         // ✅ Save user data to storage
//         storageService.saveUserId(user.id);
//         storageService.saveUserName(user.name ?? '');
//         storageService.saveUserPhone(user.phoneNumber);
//         if (user.email != null) {
//           storageService.saveUserEmail(user.email!);
//         }
//         if (user.profileImage != null) {
//           storageService.saveUserProfileImage(user.profileImage!);
//         }
//         storageService.saveIsAdmin(user.isAdmin ?? false);
//         storageService.saveLoginStatus(true);

//         emit(Authenticated(user, token));
//       },
//     );
//   }

//   Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
//     emit(AuthLoading());
//     await logout.call();
//     // ✅ Clear all auth data
//     await storageService.clearAuthData();
//     emit(Unauthenticated());
//   }

//   // ✅ Helper method to get current token
//   Future<String?> getCurrentToken() async {
//     return await storageService.getAuthToken();
//   }
// }
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/core/services/chat_socket_service.dart'; // 🚨 ADDED IMPORT
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
import '../../domain/entities/user.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendOtp sendOtp;
  final VerifyOtp verifyOtp;
  final CompleteProfile completeProfile;
  final UploadProfileImage uploadProfileImage;
  final GetCurrentUser getCurrentUser;
  final CheckAuthStatus checkAuthStatus;
  final Logout logout;
  final StorageService storageService;
  final ChatSocketService chatSocketService; // 🚨 ADDED FIELD

  AuthBloc({
    required this.sendOtp,
    required this.verifyOtp,
    required this.completeProfile,
    required this.uploadProfileImage,
    required this.getCurrentUser,
    required this.checkAuthStatus,
    required this.logout,
    required this.storageService,
    required this.chatSocketService, // 🚨 ADDED PARAM
  }) : super(AuthInitial()) {
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<CompleteProfileEvent>(_onCompleteProfile);
    on<UploadProfileImageEvent>(_onUploadProfileImage);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onSendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {
    developer.log('📞 Sending OTP for: ${event.phoneNumber}');
    emit(AuthLoading());
    try {
      final result = await sendOtp(event.phoneNumber);
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (debugOtp) => emit(OtpSent(debugOtp)),
      );
    } catch (e) {
      emit(AuthError('An unexpected error occurred: $e'));
    }
  }

  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await verifyOtp(event.phoneNumber, event.otpCode);
    await result.fold((failure) async => emit(AuthError(failure.message)), (
      data,
    ) async {
      await storageService.saveAuthToken(data.token);
      await storageService.saveUserId(data.user.id);
      await storageService.saveLoginStatus(true);
      await storageService.saveUserName(data.user.name ?? '');
      await storageService.saveUserPhone(data.user.phoneNumber);
      if (data.user.email != null)
        await storageService.saveUserEmail(data.user.email!);
      if (data.user.profileImage != null)
        await storageService.saveUserProfileImage(data.user.profileImage!);
      await storageService.saveIsAdmin(data.user.isAdmin ?? false);

      chatSocketService.connect(); // 🚨 CONNECT WEBSOCKET IMMEDIATELY

      emit(OtpVerified(data.token, data.user));
    });
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
    await result.fold((failure) async => emit(AuthError(failure.message)), (
      data,
    ) async {
      await storageService.saveUserName(event.name);
      if (event.profileImageUrl != null)
        await storageService.saveUserProfileImage(event.profileImageUrl!);
      await storageService.saveLoginStatus(true);

      chatSocketService.connect(); // 🚨 CONNECT WEBSOCKET
      emit(ProfileCompleted(data.token, data.user));
    });
  }

  Future<void> _onUploadProfileImage(
    UploadProfileImageEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await uploadProfileImage(event.base64Image);
    await result.fold((failure) async => emit(AuthError(failure.message)), (
      imageUrl,
    ) async {
      await storageService.saveUserProfileImage(imageUrl);
      emit(ProfileImageUploaded(imageUrl));
    });
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthChecking());
    final isAuthenticated = await storageService.isAuthenticated();

    if (!isAuthenticated) {
      emit(Unauthenticated());
      return;
    }

    final token = await storageService.getAuthToken();
    if (token == null || token.isEmpty) {
      emit(Unauthenticated());
      return;
    }

    chatSocketService.connect(); // 🚨 CONNECT WEBSOCKET ON APP RESTART

    final userResult = await getCurrentUser();
    await userResult.fold(
      (failure) async {
        final name = await storageService.getUserName() ?? 'User';
        final phone = await storageService.getUserPhone() ?? '';
        final email = await storageService.getUserEmail();
        final profileImage = await storageService.getUserProfileImage();
        final userId = await storageService.getUserId() ?? '';
        final isAdmin = await storageService.getIsAdmin();

        final localUser = User(
          id: userId,
          phoneNumber: phone,
          name: name,
          email: email,
          profileImage: profileImage,
          isVerified: true,
          hasProfile: name.isNotEmpty,
          isAdmin: isAdmin,
        );
        emit(Authenticated(localUser, token));
      },
      (user) async {
        await storageService.saveUserId(user.id);
        await storageService.saveUserName(user.name ?? '');
        await storageService.saveUserPhone(user.phoneNumber);
        if (user.email != null) await storageService.saveUserEmail(user.email!);
        if (user.profileImage != null)
          await storageService.saveUserProfileImage(user.profileImage!);
        await storageService.saveIsAdmin(user.isAdmin ?? false);
        await storageService.saveLoginStatus(true);
        emit(Authenticated(user, token));
      },
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    chatSocketService.disconnect(); // 🚨 DISCONNECT WEBSOCKET ON LOGOUT
    emit(AuthLoading());
    await logout.call();
    await storageService.clearAuthData();
    emit(Unauthenticated());
  }

  Future<String?> getCurrentToken() async =>
      await storageService.getAuthToken();
}
