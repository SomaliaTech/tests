// lib/features/auth/presentation/bloc/auth_bloc.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
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

  // ✅ Clear ALL Hive caches on logout
  Future<void> _clearAllCaches() async {
    try {
      final boxesToClear = [
        'conversations_cache',
        'messages_cache',
        'sync_timestamps',
      ];

      for (final boxName in boxesToClear) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box<String>(boxName);
            await box.clear();
          }
        } catch (e) {
          developer.log('❌ Error clearing $boxName: $e');
        }
      }

      developer.log('🗑️ All chat caches cleared on logout');
    } catch (e) {
      developer.log('❌ Error clearing caches: $e');
    }
  }

  Future<void> _registerDeviceToken(String token) async {
    try {
      final authToken = await storageService.getAuthToken();
      if (authToken == null) return;

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
      }
    } catch (e) {
      developer.log('❌ Failed to register token: $e');
    }
  }

  Future<void> _onSendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {
    developer.log('📞 Sending OTP for: ${event.phoneNumber}');
    if (!emit.isDone) emit(AuthLoading());
    try {
      final result = await sendOtp(event.phoneNumber);
      if (isClosed || emit.isDone) return;
      result.fold(
        (failure) {
          if (!emit.isDone) emit(AuthError(failure.message));
        },
        (debugOtp) {
          if (!emit.isDone) emit(OtpSent(debugOtp));
        },
      );
    } catch (e) {
      if (!emit.isDone) emit(AuthError('An unexpected error occurred: $e'));
    }
  }

  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (!emit.isDone) emit(AuthLoading());
    final result = await verifyOtp(event.phoneNumber, event.otpCode);
    if (isClosed || emit.isDone) return;
    await result.fold(
      (failure) async {
        if (!emit.isDone) emit(AuthError(failure.message));
      },
      (data) async {
        await storageService.saveAuthToken(data.token);
        await storageService.saveUserId(data.user.id);
        await storageService.saveLoginStatus(true);
        await storageService.saveUserName(data.user.name ?? '');
        await storageService.saveUserPhone(data.user.phoneNumber);
        if (data.user.profileImage != null) {
          await storageService.saveUserProfileImage(data.user.profileImage!);
        }
        await storageService.saveIsAdmin(data.user.isAdmin ?? false);
        await storageService.saveIsSuperAdmin(data.user.isSuperAdmin ?? false);

        try {
          final pushService = PushNotificationService();
          final token = await pushService.getToken();
          if (token != null) await _registerDeviceToken(token);
        } catch (e) {
          developer.log('⚠️ Could not register token: $e');
        }

        chatSocketService.connect();
        if (!emit.isDone) emit(OtpVerified(data.token, data.user));
      },
    );
  }

  Future<void> _onCompleteProfile(
    CompleteProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (!emit.isDone) emit(AuthLoading());
    final result = await completeProfile(
      name: event.name,
      marketId: event.marketId,
      profileImageUrl: event.profileImageUrl,
    );
    if (isClosed || emit.isDone) return;
    await result.fold(
      (failure) async {
        if (!emit.isDone) emit(AuthError(failure.message));
      },
      (data) async {
        await storageService.saveUserName(event.name);
        await storageService.saveUserMarketId(event.marketId);
        if (event.profileImageUrl != null) {
          await storageService.saveUserProfileImage(event.profileImageUrl!);
        }
        if (data.user != null) {
          await storageService.saveIsSuperAdmin(
            data.user.isSuperAdmin ?? false,
          );
          await storageService.saveIsAdmin(data.user.isAdmin ?? false);
        }
        await storageService.saveLoginStatus(true);
        chatSocketService.connect();
        if (!emit.isDone) emit(ProfileCompleted(data.token, data.user));
      },
    );
  }

  Future<void> _onUploadProfileImage(
    UploadProfileImageEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (!emit.isDone) emit(AuthLoading());
    final result = await uploadProfileImage(event.base64Image);
    if (isClosed || emit.isDone) return;
    await result.fold(
      (failure) async {
        if (!emit.isDone) emit(AuthError(failure.message));
      },
      (imageUrl) async {
        await storageService.saveUserProfileImage(imageUrl);
        if (!emit.isDone) emit(ProfileImageUploaded(imageUrl));
      },
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    final isAuthenticated = await storageService.isAuthenticated();
    if (!isAuthenticated) {
      if (!emit.isDone) emit(Unauthenticated());
      return;
    }
    final token = await storageService.getAuthToken();
    if (token == null || token.isEmpty) {
      if (!emit.isDone) emit(Unauthenticated());
      return;
    }

    final cachedName = await storageService.getUserName() ?? 'User';
    final cachedPhone = await storageService.getUserPhone() ?? '';
    final cachedProfileImage = await storageService.getUserProfileImage();
    final cachedUserId = await storageService.getUserId() ?? '';
    final cachedIsAdmin = await storageService.getIsAdmin();
    final cachedIsSuperAdmin = await storageService.getIsSuperAdmin();

    final localUser = User(
      id: cachedUserId,
      phoneNumber: cachedPhone,
      name: cachedName,
      profileImage: cachedProfileImage,
      isVerified: true,
      hasProfile: cachedName.isNotEmpty,
      isAdmin: cachedIsAdmin,
      isSuperAdmin: cachedIsSuperAdmin,
    );

    if (!emit.isDone) emit(Authenticated(localUser, token));
    chatSocketService.connect();

    try {
      final userResult = await getCurrentUser();
      if (isClosed || emit.isDone) return;
      await userResult.fold((failure) async {}, (user) async {
        await storageService.saveUserId(user.id);
        await storageService.saveUserName(user.name ?? '');
        await storageService.saveUserPhone(user.phoneNumber);
        if (user.profileImage != null)
          await storageService.saveUserProfileImage(user.profileImage!);
        await storageService.saveIsAdmin(user.isAdmin ?? false);
        await storageService.saveIsSuperAdmin(user.isSuperAdmin ?? false);
        await storageService.saveLoginStatus(true);
        if (!isClosed && !emit.isDone && state is Authenticated) {
          emit(Authenticated(user, token));
        }
      });
    } catch (e) {}
  }

  // ✅ Fixed logout - clears caches before emitting Unauthenticated
  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    chatSocketService.disconnect();
    developer.log('🔌 WebSocket disconnected on logout');

    await logout.call();
    await storageService.clearAuthData();

    // ✅ Clear all Hive caches so old user data doesn't show for new user
    await _clearAllCaches();

    if (!emit.isDone) {
      emit(Unauthenticated());
    }
  }

  Future<String?> getCurrentToken() async =>
      await storageService.getAuthToken();
}
