import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/services/push_notification_service.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
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
import 'dart:convert'; // ✅ Add this
import 'package:http/http.dart' as http; // ✅ Add this
import 'package:mobile/core/constants/api_constants.dart'; // ✅ Add this

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendOtp sendOtp;
  final VerifyOtp verifyOtp;
  final CompleteProfile completeProfile;
  final UploadProfileImage uploadProfileImage;
  final GetCurrentUser getCurrentUser;
  final CheckAuthStatus checkAuthStatus;
  final Logout logout;
  final StorageService storageService;
  final ChatSocketService chatSocketService;

  AuthBloc({
    required this.sendOtp,
    required this.verifyOtp,
    required this.completeProfile,
    required this.uploadProfileImage,
    required this.getCurrentUser,
    required this.checkAuthStatus,
    required this.logout,
    required this.storageService,
    required this.chatSocketService,
  }) : super(AuthInitial()) {
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<CompleteProfileEvent>(_onCompleteProfile);
    on<UploadProfileImageEvent>(_onUploadProfileImage);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LogoutEvent>(_onLogout);
  }
  Future<void> _registerDeviceToken(String token) async {
    try {
      final authToken = await storageService.getAuthToken();
      if (authToken == null) return;

      // ✅ FIX: Use the imported http package directly, not with import()
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/chat/device-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'token': token, 'platform': 'web'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        developer.log('📱 Device token registered successfully');
      } else {
        developer.log('❌ Failed to register token: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ Failed to register token: $e');
    }
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

      // ✅ Register device token after login
      try {
        final pushService = PushNotificationService();
        final token = await pushService.getToken();
        if (token != null) {
          await _registerDeviceToken(token);
          developer.log('📱 Device token registered after login');
        }
      } catch (e) {
        developer.log('⚠️ Could not register token: $e');
      }

      // ✅ Connect WebSocket after successful login
      chatSocketService.connect();
      developer.log('🔌 WebSocket connect() called after login');

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
      email: event.email, // ✅ Pass email
      marketId: event.marketId, // ✅ Pass marketId
      profileImageUrl: event.profileImageUrl,
    );
    await result.fold((failure) async => emit(AuthError(failure.message)), (
      data,
    ) async {
      await storageService.saveUserName(event.name);
      await storageService.saveUserEmail(event.email); // ✅ Save email
      await storageService.saveUserMarketId(event.marketId); // ✅ Save marketId
      if (event.profileImageUrl != null)
        await storageService.saveUserProfileImage(event.profileImageUrl!);
      await storageService.saveLoginStatus(true);

      chatSocketService.connect();
      developer.log('🔌 WebSocket connect() after profile completion');

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

    // ✅ Connect on app restart (already logged in)
    chatSocketService.connect();
    developer.log('🔌 WebSocket connect() on app restart');

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
    chatSocketService.disconnect(); // ✅ Disconnect on logout
    developer.log('🔌 WebSocket disconnected on logout');
    emit(AuthLoading());
    await logout.call();
    await storageService.clearAuthData();
    emit(Unauthenticated());
  }

  Future<String?> getCurrentToken() async =>
      await storageService.getAuthToken();
}
