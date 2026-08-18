// lib/main.dart - Fixed version
import 'dart:io';
import 'package:hive_flutter/adapters.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/common/widgets/splash_screen.dart';
import 'package:mobile/core/network/internet_banner.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_role/admin_role_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/banner/admin_banner_bloc.dart';
import 'package:mobile/features/auth/presentation/screens/complete_profile_screen.dart';
import 'package:mobile/features/product/presentation/blocs/banner/banner_bloc.dart';
import 'package:mobile/features/product/presentation/screens/category_view.dart';
import 'package:mobile/features/product/presentation/screens/product_detail_screen.dart';
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
import 'package:flutter/painting.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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
    Hive.openBox<String>('conversations_cache'),
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
    // 1. Clear Flutter's internal memory cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    // 2. Clear CachedNetworkImage disk cache (if you use the package)
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // 2. Clear CachedNetworkImage disk cache completely
      await DefaultCacheManager().emptyCache();
    } catch (_) {}

    // 3. Nuke the corrupted temporary directories completely
    final cacheDir = await getTemporaryDirectory();

    final libCache = Directory('${cacheDir.path}/libCachedImageData');
    if (await libCache.exists()) {
      await libCache.delete(recursive: true);
    }

    final imageCacheDir = Directory('${cacheDir.path}/images');
    if (await imageCacheDir.exists()) {
      await imageCacheDir.delete(recursive: true);
    }

    debugPrint('🗑️ Successfully cleared all corrupted image caches');
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
  bool _socketConnected = false;

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
          // ✅ Only connect if not already connected
          final socketService = sl<ChatSocketService>();
          if (!socketService.isConnected && !_socketConnected) {
            _socketConnected = true;
            socketService.connect().then((_) {
              _socketConnected = false;
            });
          }
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
          BlocProvider(create: (context) => sl<AdminRoleBloc>()),
          BlocProvider(create: (_) => sl<FaqBloc>()),
          BlocProvider(create: (_) => sl<AdminBannerBloc>()),
          BlocProvider(create: (_) => sl<BannerBloc>()),
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
          // ✅ Use a separate method for home to avoid rebuilds
          home: _buildHome(),
          onGenerateRoute: (settings) {
            if (settings.name == '/product-details') {
              final args = settings.arguments as Map<String, dynamic>?;
              final productId = args?['productId'] as String? ?? '';

              return MaterialPageRoute(
                builder: (context) => ProductDetailScreen(productId: productId),
              );
            }

            if (settings.name == '/category-products') {
              final args = settings.arguments as Map<String, dynamic>?;
              final categoryId = args?['categoryId'] as String? ?? '';
              final categoryName =
                  args?['categoryName'] as String? ?? 'Products';

              return MaterialPageRoute(
                builder: (context) => CategoryView(
                  categoryId: categoryId,
                  categoryName: categoryName,
                ),
              );
            }

            // Fallback for any other undefined routes
            return null;
          },
          routes: {'/home': (context) => const MainNavigationScreen()},
        ),
      ),
    );
  }

  // ✅ Separate method to build the home widget
  Widget _buildHome() {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        // ✅ Show splash screen while connectivity is being checked
        if (connectivity.isInitialCheck && !widget.isInitiallyAuthenticated) {
          return const SplashScreen();
        }

        // ✅ If already authenticated, go directly to home
        if (widget.isInitiallyAuthenticated) {
          return const MainNavigationScreen();
        }

        // ✅ Use BlocBuilder with buildWhen to prevent unnecessary rebuilds
        return BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (previous, current) {
            // ✅ Only rebuild for meaningful state changes, not loading
            if (current is AuthLoading) return false;
            if (previous is AuthLoading && current is! AuthLoading) return true;
            return true;
          },
          builder: (context, state) {
            // ✅ Don't rebuild on AuthLoading to prevent flicker
            if (state is AuthLoading) {
              // Return the current widget without rebuilding
              return const SizedBox.shrink();
            }

            if (state is AuthChecking) {
              return const SplashScreen();
            } else if (state is Authenticated) {
              return const MainNavigationScreen();
            } else if (state is Unauthenticated) {
              return const PhoneInputScreen();
            } else if (state is OtpVerified) {
              // ✅ Handle OtpVerified state here too
              if (state.isGoogleSignIn) {
                return CompleteProfileScreen(
                  token: state.token,
                  user: state.user,
                  isGoogleSignIn: true,
                );
              } else {
                if (state.user.hasProfile) {
                  return const MainNavigationScreen();
                } else {
                  return CompleteProfileScreen(
                    token: state.token,
                    user: state.user,
                    isGoogleSignIn: false,
                  );
                }
              }
            } else if (state is ProfileCompleted) {
              return const MainNavigationScreen();
            } else if (state is AuthError) {
              // Show error and go back to login
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  // Error is already shown in the screen
                }
              });
              return const PhoneInputScreen();
            } else {
              return const SplashScreen();
            }
          },
        );
      },
    );
  }
}
