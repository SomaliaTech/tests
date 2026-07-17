import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/services/address_injection.dart';
import 'package:mobile/core/services/admin_feq_ijection.dart';
import 'package:mobile/core/services/admin_injection.dart';
import 'package:mobile/core/services/analytics_injection.dart';
import 'package:mobile/core/services/auth_ijdection.dart';
import 'package:mobile/core/services/cart_injection.dart';
import 'package:mobile/core/services/dashboard_injection.dart';
import 'package:mobile/core/services/notification_injection.dart';
import 'package:mobile/core/services/order_injection.dart';
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

  sl.registerLazySingleton<ServerStatusService>(() => ServerStatusService());
  sl.registerLazySingleton(() => GetAdminUsers(sl()));

  // ==========================================
  // ✅ Register each dependency group ONLY ONCE
  // ==========================================
  registerCategoryDependencies(sl); // ✅ ONCE
  registerProductDependencies(sl); // ✅ ONCE
  registerWishlistDependencies(sl); // ✅ ONCE
  authRegisterDependencies(sl); // ✅ ONCE
  registerProfileDependencies(sl); // ✅ ONCE
  addressRegisterDependencies(sl); // ✅ ONCE
  registerMarketDependencies(sl); // ✅ ONCE
  orderRegisterDependencies(sl); // ✅ ONCE
  registerCartDependencies(sl); // ✅ ONCE
  registerAdminDependencies(sl); // ✅ ONCE
  registerDashboardDependencies(sl); // ✅ ONCE
  trackingRegisterDependencies(sl); // ✅ ONCE
  registerNotificationDependencies(); // ✅ ONCE
  registerChatDependencies(); // ✅ ONCE
  registerSupportDependencies(sl);
  registerAdminFaqDependencies(sl);
  registerAnalyticsDependencies(sl);

  // ❌ REMOVED THESE DUPLICATES:
  // registerCategoryDependencies(sl);  ← DUPLICATE
  // registerProductDependencies(sl);   ← DUPLICATE
}
