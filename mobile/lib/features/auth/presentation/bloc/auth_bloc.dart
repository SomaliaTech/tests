import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/services/push_notification_service.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/features/auth/domain/usecases/complete_profile.dart';
import 'package:mobile/features/auth/domain/usecases/facebook_sign_in.dart';
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
import 'dart:io' show Platform;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

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
  final FacebookSignIn facebookSignInUseCase;

  bool _isGoogleSignInProgress = false;
  bool _isFacebookSignInProgress = false;

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
    required this.facebookSignInUseCase,
    required this.googleSignInUseCase,
  }) : super(AuthInitial()) {
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<CompleteProfileEvent>(_onCompleteProfile);
    on<UploadProfileImageEvent>(_onUploadProfileImage);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LogoutEvent>(_onLogout);
    on<GoogleSignInEvent>(_onGoogleSignIn);
    on<FacebookSignInEvent>(_onFacebookSignIn);
  }

  // ==========================================
  // 🔐 GOOGLE SIGN IN
  // ==========================================

  Future<void> _onGoogleSignIn(
    GoogleSignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (_isGoogleSignInProgress) {
      developer.log('⏳ Google sign-in already in progress, skipping...');
      return;
    }

    developer.log('🟡 GOOGLE SIGN IN STARTED');

    if (!emit.isDone && state is! AuthLoading) {
      emit(AuthLoading());
    }

    _isGoogleSignInProgress = true;

    try {
      final String clientId = Platform.isIOS
          ? "159665748516-q57ehiuvg427bluh15gdj701disc746r.apps.googleusercontent.com"
          : "159665748516-9kan2pvb50ap4uvdc3djkpr9g73p0nt5.apps.googleusercontent.com";

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: clientId,
        serverClientId:
            "159665748516-bffn5l47e89cmjs2bl1nsif7q2k79u3v.apps.googleusercontent.com",
      );

      try {
        await googleSignIn.signOut();
      } catch (e) {
        developer.log('⚠️ Sign out failed: $e');
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _isGoogleSignInProgress = false;
        if (!emit.isDone) {
          emit(AuthError('Google sign in cancelled'));
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        _isGoogleSignInProgress = false;
        if (!emit.isDone) {
          emit(AuthError('Failed to get Google ID token'));
        }
        return;
      }

      final result = await googleSignInUseCase(idToken);

      if (isClosed || emit.isDone) {
        _isGoogleSignInProgress = false;
        return;
      }

      // ✅ FIX: Await the fold so we can await the saves inside it
      await result.fold(
        (failure) async {
          _isGoogleSignInProgress = false;
          if (!emit.isDone) {
            emit(AuthError(failure.message));
          }
        },
        (data) async {
          // ✅ FIX: Wait for data to be saved BEFORE navigating
          await _saveGoogleUserData(data);

          final bool needsProfile =
              data.user.marketId == null ||
              data.user.marketId!.isEmpty ||
              !data.user.hasProfile;

          _isGoogleSignInProgress = false;

          if (needsProfile) {
            if (!emit.isDone) {
              emit(OtpVerified(data.token, data.user, isGoogleSignIn: true));
            }
          } else {
            if (!emit.isDone) {
              emit(Authenticated(data.user, data.token));
            }
          }
        },
      );
    } catch (e) {
      _isGoogleSignInProgress = false;
      developer.log('❌ Google sign in error: $e');
      if (!emit.isDone) {
        emit(AuthError('Google sign in failed. Please try again.'));
      }
    }
  }

  // ==========================================
  // 🔐 FACEBOOK SIGN IN
  // ==========================================

  Future<void> _onFacebookSignIn(
    FacebookSignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (_isFacebookSignInProgress) {
      developer.log('⏳ Facebook sign-in already in progress, skipping...');
      return;
    }

    _isFacebookSignInProgress = true;
    emit(AuthLoading());

    try {
      final result = await facebookSignInUseCase(event.accessToken);

      if (isClosed || emit.isDone) {
        _isFacebookSignInProgress = false;
        return;
      }

      // ✅ FIX: Await the fold so we can await the saves inside it
      await result.fold(
        (failure) async {
          _isFacebookSignInProgress = false;
          if (!emit.isDone) {
            emit(AuthError(failure.message));
          }
        },
        (data) async {
          // ✅ FIX: Wait for data to be saved BEFORE navigating
          await _saveFacebookUserData(data);

          final bool needsProfile =
              (data.user.name == null || data.user.name!.trim().isEmpty) ||
              data.user.phoneNumber.isEmpty ||
              data.user.marketId == null ||
              data.user.marketId!.isEmpty ||
              !data.user.hasProfile;

          _isFacebookSignInProgress = false;

          developer.log(
            '📘 Facebook user - Name: "${data.user.name}", Phone: "${data.user.phoneNumber}", Market: "${data.user.marketId}", hasProfile: ${data.user.hasProfile}',
          );

          if (needsProfile) {
            developer.log('📘 Facebook user needs to complete profile');
            if (!emit.isDone) {
              emit(OtpVerified(data.token, data.user, isGoogleSignIn: false));
            }
          } else {
            developer.log(
              '📘 Facebook user has complete profile in DB, authenticating directly',
            );
            if (!emit.isDone) {
              emit(Authenticated(data.user, data.token));
            }
          }
        },
      );
    } catch (e) {
      _isFacebookSignInProgress = false;
      developer.log('❌ Facebook sign in error: $e');
      if (!emit.isDone) {
        emit(AuthError('Facebook sign in failed. Please try again.'));
      }
    }
  }

  // ==========================================
  // 💾 SAVE USER DATA SECURELY
  // ==========================================

  // ✅ FIX: Removed Future(() async {}) wrapper. Now returns a Future and runs synchronously in the event loop.
  Future<void> _saveGoogleUserData(dynamic data) async {
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

      if (data.user.phoneNumber != null &&
          data.user.phoneNumber.toString().isNotEmpty) {
        await storageService.saveUserPhone(data.user.phoneNumber.toString());
      }
      if (data.user.marketId != null &&
          data.user.marketId.toString().isNotEmpty) {
        await storageService.saveUserMarketId(data.user.marketId.toString());
      }

      await storageService.saveIsAdmin(data.user.isAdmin ?? false);
      await storageService.saveIsSuperAdmin(data.user.isSuperAdmin ?? false);

      developer.log('🔵 Google user data saved securely');

      try {
        final pushService = PushNotificationService();
        final token = await pushService.getToken();
        if (token != null) await _registerDeviceToken(token);
      } catch (e) {
        developer.log('⚠️ Could not register token: $e');
      }

      // Socket connection can remain fire-and-forget so it doesn't block UI
      chatSocketService.connect();
    } catch (e) {
      developer.log('❌ Error saving Google user data: $e');
    }
  }

  // ✅ FIX: Removed Future(() async {}) wrapper. Now returns a Future and runs synchronously in the event loop.
  Future<void> _saveFacebookUserData(dynamic data) async {
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

      if (data.user.phoneNumber != null &&
          data.user.phoneNumber.toString().isNotEmpty) {
        await storageService.saveUserPhone(data.user.phoneNumber.toString());
      }
      if (data.user.marketId != null &&
          data.user.marketId.toString().isNotEmpty) {
        await storageService.saveUserMarketId(data.user.marketId.toString());
      }

      await storageService.saveIsAdmin(data.user.isAdmin ?? false);
      await storageService.saveIsSuperAdmin(data.user.isSuperAdmin ?? false);

      developer.log('🔵 Facebook user data saved securely');

      try {
        final pushService = PushNotificationService();
        final token = await pushService.getToken();
        if (token != null) await _registerDeviceToken(token);
      } catch (e) {
        developer.log('⚠️ Could not register token: $e');
      }

      chatSocketService.connect();
    } catch (e) {
      developer.log('❌ Error saving Facebook user data: $e');
    }
  }

  // ==========================================
  // 📞 SEND OTP
  // ==========================================

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
        (message) {
          if (!emit.isDone) emit(OtpSent(message));
        },
      );
    } catch (e) {
      if (!emit.isDone) emit(AuthError('An unexpected error occurred: $e'));
    }
  }

  // ==========================================
  // ✅ VERIFY OTP
  // ==========================================

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
        if (!emit.isDone) {
          emit(OtpVerified(data.token, data.user, isGoogleSignIn: false));
        }
      },
    );
  }

  // ==========================================
  // 👤 COMPLETE PROFILE
  // ==========================================

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

        await storageService.saveIsSuperAdmin(data.user.isSuperAdmin ?? false);
        await storageService.saveIsAdmin(data.user.isAdmin ?? false);
        await storageService.saveLoginStatus(true);
        chatSocketService.connect();
        if (!emit.isDone) emit(ProfileCompleted(data.token, data.user));
      },
    );
  }

  // ==========================================
  // 📸 UPLOAD PROFILE IMAGE
  // ==========================================

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

  // ==========================================
  // 🔍 CHECK AUTH STATUS
  // ==========================================

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (kReleaseMode && !(await StorageService.isDeviceSecure())) {
      developer.log('⚠️ Device may be compromised, clearing auth data');
      await storageService.clearAuthData();
      if (!emit.isDone) emit(Unauthenticated());
      return;
    }

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

    if (!(await storageService.isValidToken())) {
      developer.log('🔴 Token expired, logging out...');
      await _clearAllCaches();
      await storageService.clearAuthData();
      chatSocketService.disconnect();
      if (!emit.isDone) emit(Unauthenticated());
      return;
    }

    final cachedName = await storageService.getUserName() ?? '';
    final cachedPhone = await storageService.getUserPhone() ?? '';
    final cachedMarketId = await storageService.getUserMarketId() ?? '';
    final cachedProfileImage = await storageService.getUserProfileImage();
    final cachedUserId = await storageService.getUserId() ?? '';
    final cachedIsAdmin = await storageService.getIsAdmin();
    final cachedIsSuperAdmin = await storageService.getIsSuperAdmin();

    final bool isLocallyComplete =
        cachedName.isNotEmpty &&
        cachedPhone.isNotEmpty &&
        cachedMarketId.isNotEmpty;

    final localUser = User(
      id: cachedUserId,
      phoneNumber: cachedPhone,
      name: cachedName,
      profileImage: cachedProfileImage,
      isVerified: true,
      hasProfile: isLocallyComplete,
      isAdmin: cachedIsAdmin,
      isSuperAdmin: cachedIsSuperAdmin,
      marketId: cachedMarketId,
    );

    if (!emit.isDone && state is! Authenticated) {
      emit(Authenticated(localUser, token));
    }

    chatSocketService.connect();

    try {
      final userResult = await getCurrentUser();
      if (isClosed || emit.isDone) return;

      await userResult.fold(
        (failure) async {
          developer.log('Failed to get current user: ${failure.message}');

          if (failure.message.contains('401') ||
              failure.message.contains('Unauthorized') ||
              failure.message.contains('expired') ||
              failure.message.contains('invalid token')) {
            developer.log('🔴 Token expired or invalid. Logging out...');
            await _clearAllCaches();
            await storageService.clearAuthData();
            chatSocketService.disconnect();

            if (!emit.isDone) emit(Unauthenticated());
          }
        },
        (user) async {
          await storageService.saveUserId(user.id);
          await storageService.saveUserName(user.name ?? '');
          if (user.phoneNumber.isNotEmpty) {
            await storageService.saveUserPhone(user.phoneNumber);
          }
          if (user.marketId != null && user.marketId!.isNotEmpty) {
            await storageService.saveUserMarketId(user.marketId!);
          }
          if (user.profileImage != null) {
            await storageService.saveUserProfileImage(user.profileImage!);
          }
          await storageService.saveIsAdmin(user.isAdmin ?? false);
          await storageService.saveIsSuperAdmin(user.isSuperAdmin ?? false);
          await storageService.saveLoginStatus(true);

          if (!isClosed && !emit.isDone && state is Authenticated) {
            final currentState = state as Authenticated;
            if (currentState.user != user) {
              emit(Authenticated(user, token));
            }
          }
        },
      );
    } catch (e) {
      developer.log('Error checking auth status: $e');
    }
  }

  // ==========================================
  // 🚪 LOGOUT
  // ==========================================

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      developer.log('🔵 Google sign out completed');
    } catch (e) {
      developer.log('⚠️ Google sign out failed: $e');
    }

    try {
      await FacebookAuth.instance.logOut();
      developer.log('🔵 Facebook sign out completed');
    } catch (e) {
      developer.log('⚠️ Facebook sign out failed: $e');
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

  // ==========================================
  // 🗑️ CLEAR CACHES
  // ==========================================

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

  // ==========================================
  // 📱 REGISTER DEVICE TOKEN
  // ==========================================

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

  Future<String?> getCurrentToken() async =>
      await storageService.getAuthToken();
}
