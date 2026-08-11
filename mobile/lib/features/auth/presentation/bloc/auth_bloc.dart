// lib/features/auth/presentation/bloc/auth_bloc.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/services/push_notification_service.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/features/auth/domain/usecases/complete_profile.dart';
import 'package:mobile/features/auth/domain/usecases/google_sign_in.dart'
    as google_use_case;
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
  final google_use_case.GoogleSignIn googleSignInUseCase;

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
    required this.googleSignInUseCase,
  }) : super(AuthInitial()) {
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<CompleteProfileEvent>(_onCompleteProfile);
    on<UploadProfileImageEvent>(_onUploadProfileImage);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LogoutEvent>(_onLogout);
    on<GoogleSignInEvent>(_onGoogleSignIn);
  }
  // In auth_bloc.dart - Complete fixed _onGoogleSignIn method
  Future<void> _onGoogleSignIn(
    GoogleSignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    developer.log('🟡 GOOGLE SIGN IN STARTED', name: 'AuthBloc');

    if (!emit.isDone) emit(AuthLoading());

    try {
      developer.log(
        '🔵 Initializing GoogleSignIn with serverClientId...',
        name: 'AuthBloc',
      );

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId:
            '159665748516-bffn5l47e89cmjs2bl1nsif7q2k79u3v.apps.googleusercontent.com',
      );

      try {
        await googleSignIn.signOut();
        developer.log('🔵 Signed out from previous session', name: 'AuthBloc');
      } catch (e) {
        developer.log(
          '⚠️ Sign out failed (might not be signed in): $e',
          name: 'AuthBloc',
        );
      }

      developer.log('🔵 Calling signIn()...', name: 'AuthBloc');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      developer.log(
        '🔵 Google sign in result: ${googleUser != null ? "SUCCESS" : "CANCELLED"}',
        name: 'AuthBloc',
      );

      if (googleUser == null) {
        developer.log('❌ User cancelled Google sign in', name: 'AuthBloc');
        if (!emit.isDone) emit(AuthError('Google sign in cancelled'));
        return;
      }

      developer.log('🔵 Getting authentication tokens...', name: 'AuthBloc');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      developer.log(
        '🔵 Access Token: ${accessToken != null ? "RECEIVED ✓" : "NULL ✗"}',
        name: 'AuthBloc',
      );
      developer.log(
        '🔵 ID Token: ${idToken != null ? "RECEIVED ✓ (${idToken.substring(0, 20)}...)" : "NULL ✗"}',
        name: 'AuthBloc',
      );

      if (idToken == null || idToken.isEmpty) {
        developer.log('❌ No ID token received from Google', name: 'AuthBloc');
        if (!emit.isDone) {
          emit(
            AuthError(
              'Failed to get ID token. Please ensure Google Cloud Console is properly configured.',
            ),
          );
        }
        return;
      }

      final String email = googleUser.email;
      final String displayName = googleUser.displayName ?? '';
      final String? photoUrl = googleUser.photoUrl;

      developer.log(
        '🔵 User info - Email: $email, Name: $displayName',
        name: 'AuthBloc',
      );
      developer.log('🔵 Calling backend with ID token...', name: 'AuthBloc');

      final result = await googleSignInUseCase(
        idToken,
        email,
        displayName,
        photoUrl,
      );

      developer.log('🔵 Backend response received', name: 'AuthBloc');

      if (isClosed || emit.isDone) {
        developer.log(
          '⚠️ Stream closed or emit.isDone before fold',
          name: 'AuthBloc',
        );
        developer.log(
          '⚠️ isClosed: $isClosed, emit.isDone: $emit.isDone',
          name: 'AuthBloc',
        );
        return;
      }

      // ✅ FIX: Handle fold SYNCHRONOUSLY for emit, then do async work separately
      result.fold(
        (failure) {
          developer.log(
            '❌ Backend failure: ${failure.message}',
            name: 'AuthBloc',
          );
          if (!emit.isDone) emit(AuthError(failure.message));
        },
        (data) {
          // ✅ CRITICAL FIX: Emit state SYNCHRONOUSLY first
          // DO NOT make this callback async!
          developer.log('✅ Google sign in SUCCESS', name: 'AuthBloc');
          developer.log(
            '🔵 User hasProfile: ${data.user.hasProfile}',
            name: 'AuthBloc',
          );
          developer.log(
            '🔵 User marketId: ${data.user.marketId}',
            name: 'AuthBloc',
          );

          developer.log(
            '🔵🔵🔵 ABOUT TO EMIT - isDone: ${emit.isDone}, isClosed: $isClosed 🔵🔵🔵',
            name: 'AuthBloc',
          );
          developer.log(
            '🔵🔵🔵 hasProfile: ${data.user.hasProfile}, marketId: ${data.user.marketId} 🔵🔵🔵',
            name: 'AuthBloc',
          );

          if (!emit.isDone) {
            if (!data.user.hasProfile || data.user.marketId == null) {
              developer.log(
                '🔵🔵🔵 EMITTING OtpVerified 🔵🔵🔵',
                name: 'AuthBloc',
              );
              emit(OtpVerified(data.token, data.user));
              developer.log(
                '🔵🔵🔵 OtpVerified EMITTED SUCCESSFULLY 🔵🔵🔵',
                name: 'AuthBloc',
              );
            } else {
              developer.log(
                '🔵🔵🔵 EMITTING Authenticated 🔵🔵🔵',
                name: 'AuthBloc',
              );
              emit(Authenticated(data.user, data.token));
              developer.log(
                '🔵🔵🔵 Authenticated EMITTED SUCCESSFULLY 🔵🔵🔵',
                name: 'AuthBloc',
              );
            }
          } else {
            developer.log(
              '❌❌❌ CANNOT EMIT - emit.isDone is TRUE ❌❌❌',
              name: 'AuthBloc',
            );
          }

          // ✅ Fire and forget async operations AFTER emit
          // These run asynchronously but don't block the emit
          _saveGoogleUserData(data);
        },
      );
    } catch (e) {
      developer.log('❌ EXCEPTION in Google sign in: $e', name: 'AuthBloc');
      if (!emit.isDone) {
        emit(AuthError('Google sign in failed: $e'));
      }
    }
  }

  // ✅ Helper method for async operations after emit
  void _saveGoogleUserData(dynamic data) {
    // Use Future to run async without blocking
    Future(() async {
      try {
        await storageService.saveAuthToken(data.token);
        await storageService.saveUserId(data.user.id);
        await storageService.saveLoginStatus(true);
        await storageService.saveUserName(data.user.name ?? '');
        if (data.user.email != null) {
          await storageService.saveUserEmail(data.user.email!);
        }
        if (data.user.profileImage != null) {
          await storageService.saveUserProfileImage(data.user.profileImage!);
        }
        await storageService.saveIsAdmin(data.user.isAdmin ?? false);
        await storageService.saveIsSuperAdmin(data.user.isSuperAdmin ?? false);

        developer.log(
          '🔵 Google user data saved successfully',
          name: 'AuthBloc',
        );

        // Register push token
        try {
          final pushService = PushNotificationService();
          final token = await pushService.getToken();
          if (token != null) _registerDeviceToken(token);
        } catch (e) {
          developer.log('⚠️ Could not register token: $e', name: 'AuthBloc');
        }

        // Connect to chat socket
        chatSocketService.connect();
        developer.log('🔵 Chat socket connected', name: 'AuthBloc');
      } catch (e) {
        developer.log('❌ Error saving Google user data: $e', name: 'AuthBloc');
      }
    });
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
      phoneNumber: event.phoneNumber,
    );
    if (isClosed || emit.isDone) return;
    await result.fold(
      (failure) async {
        if (!emit.isDone) emit(AuthError(failure.message));
      },
      (data) async {
        await storageService.saveUserName(event.name);
        await storageService.saveUserMarketId(event.marketId);
        if (event.phoneNumber != null && event.phoneNumber!.isNotEmpty) {
          await storageService.saveUserPhone(event.phoneNumber!);
        }
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
      await userResult.fold(
        (failure) async {
          developer.log('Failed to get current user: ${failure.message}');
        },
        (user) async {
          await storageService.saveUserId(user.id);
          await storageService.saveUserName(user.name ?? '');
          await storageService.saveUserPhone(user.phoneNumber);
          if (user.profileImage != null) {
            await storageService.saveUserProfileImage(user.profileImage!);
          }
          await storageService.saveIsAdmin(user.isAdmin ?? false);
          await storageService.saveIsSuperAdmin(user.isSuperAdmin ?? false);
          await storageService.saveLoginStatus(true);
          if (!isClosed && !emit.isDone && state is Authenticated) {
            emit(Authenticated(user, token));
          }
        },
      );
    } catch (e) {
      developer.log('Error checking auth status: $e');
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      developer.log('🔵 Google sign out completed', name: 'AuthBloc');
    } catch (e) {
      developer.log('⚠️ Google sign out failed: $e', name: 'AuthBloc');
    }

    chatSocketService.disconnect();
    developer.log('🔌 WebSocket disconnected on logout');

    await logout.call();
    await storageService.clearAuthData();
    await _clearAllCaches();

    if (!emit.isDone) {
      emit(Unauthenticated());
    }
  }

  Future<String?> getCurrentToken() async =>
      await storageService.getAuthToken();
}
