// lib/core/services/injection_container.dart

import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/services/address_injection.dart';
import 'package:mobile/core/services/admin_feq_ijection.dart';
import 'package:mobile/core/services/admin_injection.dart';
import 'package:mobile/core/services/admin_role_ijection.dart';
import 'package:mobile/core/services/analytics_injection.dart';
import 'package:mobile/core/services/auth_ijdection.dart';
import 'package:mobile/core/services/banner_injection.dart';
import 'package:mobile/core/services/cart_injection.dart';
import 'package:mobile/core/services/connectivity_service.dart'; // ✅ ADD THIS IMPORT
import 'package:mobile/core/services/dashboard_injection.dart';
import 'package:mobile/core/services/notification_injection.dart';
import 'package:mobile/core/services/order_injection.dart';
import 'package:mobile/core/services/permission_service.dart';
import 'package:mobile/core/services/profile_ijection.dart';
import 'package:mobile/core/services/server_status_service.dart';
import 'package:mobile/core/services/support_injection.dart';
import 'package:mobile/core/services/tracking_injection.dart';
import 'package:mobile/core/services/chat_injection.dart';
import 'package:mobile/features/chat/domain/usecases/get_admin_users.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/network_info.dart';
import 'product_injection.dart';
import 'category_injection.dart';
import 'wishlist_injection.dart';
import 'market_injection.dart';
import 'storage/storage_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // 🌐 CORE & EXTERNAL DEPENDENCIES
  sl.registerLazySingleton(() => InternetConnection());
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(internetConnection: sl()),
  );

  // http client
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // Flutter Secure Storage
  sl.registerLazySingleton(() => const FlutterSecureStorage());

  // StorageService
  sl.registerLazySingleton<StorageService>(
    () => StorageService(secureStorage: sl()),
  );

  // Shared Preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // ApiClient
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(
      client: sl<http.Client>(),
      storageService: sl<StorageService>(),
    ),
  );

  // ✅ REGISTER ConnectivityService HERE (BEFORE any BLoC that depends on it)
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  print('✅ ConnectivityService registered');

  sl.registerLazySingleton<ServerStatusService>(() => ServerStatusService());
  sl.registerLazySingleton(() => GetAdminUsers(sl()));

  if (!sl.isRegistered<PermissionService>()) {
    sl.registerLazySingleton<PermissionService>(
      () => PermissionService(storageService: sl(), client: sl()),
    );
  }

  // ==========================================
  // ✅ Register each dependency group
  // ==========================================
  registerCategoryDependencies(sl);
  registerProductDependencies(sl);
  registerWishlistDependencies(sl);
  authRegisterDependencies(sl);
  registerProfileDependencies(sl);
  addressRegisterDependencies(sl);
  registerMarketDependencies(sl);
  orderRegisterDependencies(sl);
  registerCartDependencies(sl);
  registerAdminDependencies(sl);
  registerDashboardDependencies(sl);
  trackingRegisterDependencies(sl);
  registerNotificationDependencies(sl);
  registerChatDependencies(); // ⚠️ This doesn't use sl parameter
  registerSupportDependencies(sl);
  registerAdminFaqDependencies(sl);
  registerAnalyticsDependencies(sl);
  registerAdminRoleDependencies(sl);
  registerBannerDependencies(sl);
}
