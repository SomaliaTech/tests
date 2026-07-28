// lib/main.dart
import 'dart:io';
import 'package:hive_flutter/adapters.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/network/internet_banner.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mobile/core/common/widgets/main_navigation_screen.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/injection_container.dart';
import 'package:mobile/core/services/navigation_service.dart';
import 'package:mobile/core/services/push_notification_service.dart';
import 'package:mobile/core/services/sound/message_sound_manager.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_category/admin_category_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_color_size/admin_color_size_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_market/admin_market_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/analytics/analytics_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/dashborad/dashboard_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/faq/admin_faq_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/revenue/revenue_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mobile/features/auth/presentation/screens/phone_input_screen.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:mobile/features/chat/presentation/bloc/chat_room_bloc.dart';
import 'package:mobile/features/chat/presentation/bloc/conversations_bloc.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:mobile/features/order/presentation/bloc/order_bloc.dart';
import 'package:mobile/features/order/presentation/bloc/order_details_bloc.dart';
import 'package:mobile/features/order/presentation/bloc/order_history_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/address_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/category_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/product_bloc.dart';
import 'package:mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mobile/features/support/presentation/bloc/faq_bloc.dart';
import 'package:mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:mobile/features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Initialize Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized successfully');
    }
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  // ✅ Open ALL Hive boxes FIRST with correct types
  await Future.wait([
    Hive.openBox<String>('con6versations_cache'),
    Hive.openBox<String>('messages_cache'),
    Hive.openBox<String>('sync_timestamps'),
    Hive.openBox<String>('product_cache'),
    Hive.openBox<String>('category_cache'),
  ]);

  // ✅ Initialize dependencies AFTER boxes are open
  await initDependencies();

  // Clear corrupted image cache on app start
  await clearImageCache();

  // Initialize connectivity service
  final connectivityService = ConnectivityService();
  connectivityService.initialize();

  // Initialize push notifications in background
  PushNotificationService().init().catchError((e) {
    debugPrint('⚠️ Push notification init failed: $e');
  });

  // Initialize sound manager in background
  MessageSoundManager().init().catchError((e) {
    debugPrint('⚠️ Sound manager init failed: $e');
  });

  // 🚀 Check if user is already authenticated BEFORE building the app
  final storageService = sl<StorageService>();
  final isAuthenticated = await storageService.isAuthenticated();
  final token = await storageService.getAuthToken();

  runApp(
    MyApp(
      connectivityService: connectivityService,
      isInitiallyAuthenticated:
          isAuthenticated && token != null && token.isNotEmpty,
    ),
  );
}

/// Clear corrupted/old cached images
Future<void> clearImageCache() async {
  try {
    final cacheDir = await getTemporaryDirectory();
    final cachePath = '${cacheDir.path}/libCachedImageData';
    final cacheDirObj = Directory(cachePath);

    if (await cacheDirObj.exists()) {
      int deletedCount = 0;
      final now = DateTime.now();

      await for (final entity in cacheDirObj.list(recursive: true)) {
        if (entity is File) {
          bool shouldDelete = false;

          try {
            final stat = await entity.stat();
            final age = now.difference(stat.modified);

            // Delete if older than 24 hours
            if (age.inHours > 24) {
              shouldDelete = true;
            }

            // Delete if too small (likely corrupted)
            if (stat.size < 500) {
              shouldDelete = true;
            }
          } catch (e) {
            // Can't read file info - it's corrupted, delete it
            shouldDelete = true;
          }

          if (shouldDelete) {
            try {
              await entity.delete();
              deletedCount++;
            } catch (_) {}
          }
        }
      }

      if (deletedCount > 0) {
        debugPrint('🗑️ Cleared $deletedCount cached image files');
      }
    }
  } catch (e) {
    debugPrint('⚠️ Error clearing image cache: $e');
  }
}

class MyApp extends StatefulWidget {
  final ConnectivityService connectivityService;
  final bool isInitiallyAuthenticated;

  const MyApp({
    super.key,
    required this.connectivityService,
    required this.isInitiallyAuthenticated,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final authState = sl<AuthBloc>().state;
      if (authState is Authenticated ||
          authState is OtpVerified ||
          authState is ProfileCompleted) {
        if (widget.connectivityService.status != ConnectionStatus.offline) {
          sl<ChatSocketService>().connect();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: widget.connectivityService),
          BlocProvider(
            create: (context) =>
                sl<AuthBloc>()..add(const CheckAuthStatusEvent()),
          ),
          BlocProvider(create: (context) => sl<CartBloc>()),
          BlocProvider(create: (context) => sl<OrderBloc>()),
          BlocProvider(create: (context) => sl<ProductBloc>()),
          BlocProvider(create: (context) => sl<WishlistBloc>()),
          BlocProvider(create: (context) => sl<ProfileBloc>()),
          BlocProvider(create: (context) => sl<CategoryBloc>()),
          BlocProvider(create: (context) => sl<TrackingBloc>()),
          BlocProvider(create: (context) => sl<OrderHistoryBloc>()),
          BlocProvider(create: (context) => sl<AddressBloc>()),
          BlocProvider(create: (context) => sl<OrderDetailsBloc>()),
          BlocProvider(create: (context) => sl<AdminBloc>()),
          BlocProvider(create: (context) => sl<DashboardBloc>()),
          BlocProvider(create: (context) => sl<UserBloc>()),
          BlocProvider(create: (context) => sl<RevenueBloc>()),
          BlocProvider(create: (context) => sl<AdminProductBloc>()),
          BlocProvider(create: (_) => sl<AnalyticsBloc>()),
          BlocProvider(create: (context) => sl<NotificationsBloc>()),
          BlocProvider(create: (context) => sl<ConversationsBloc>()),
          BlocProvider(create: (context) => sl<ChatRoomBloc>()),
          BlocProvider(create: (context) => sl<AdminCategoryBloc>()),
          BlocProvider(create: (context) => sl<AdminColorSizeBloc>()),
          BlocProvider(create: (context) => sl<AdminMarketBloc>()),
          BlocProvider(create: (_) => sl<FaqBloc>()),
          BlocProvider(create: (_) => sl<AdminFaqBloc>()),
          Provider<StorageService>.value(value: sl<StorageService>()),
        ],
        child: MaterialApp(
          title: 'FARXADA',
          debugShowCheckedModeBanner: false,
          navigatorKey: NavigationService.navigatorKey,
          theme: AppTheme.lightTheme,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned.fill(child: child ?? const SizedBox.shrink()),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    type: MaterialType.transparency,
                    child: const InternetBanner(),
                  ),
                ),
              ],
            );
          },
          // ✅ home property handles the root route
          home: Consumer<ConnectivityService>(
            builder: (context, connectivity, _) {
              if (connectivity.isInitialCheck &&
                  !widget.isInitiallyAuthenticated) {
                return const SplashScreen();
              }

              if (widget.isInitiallyAuthenticated) {
                return const MainNavigationScreen();
              }

              return BlocBuilder<AuthBloc, AuthState>(
                buildWhen: (previous, current) =>
                    current is AuthChecking ||
                    current is Authenticated ||
                    current is Unauthenticated,
                builder: (context, state) {
                  if (state is AuthChecking) {
                    if (widget.isInitiallyAuthenticated) {
                      return const MainNavigationScreen();
                    }
                    return const SplashScreen();
                  } else if (state is Authenticated) {
                    return const MainNavigationScreen();
                  } else if (state is Unauthenticated) {
                    return const PhoneInputScreen();
                  } else {
                    return const SplashScreen();
                  }
                },
              );
            },
          ),
          // ✅ Only non-root routes here
          routes: {'/home': (context) => const MainNavigationScreen()},
        ),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2ED573), Color(0xFF1ABC9C), Color(0xFF16A085)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              top: 120,
              left: 40,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Iconsax.shopping_bag,
                        size: 60,
                        color: Color(0xFF2ED573),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'FARXADA',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4.0,
                      shadows: [
                        Shadow(
                          color: Color(0x40000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Shopping Destination',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.9),
                      ),
                      strokeWidth: 3.0,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
