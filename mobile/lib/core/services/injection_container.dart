import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mobile/core/services/auth_ijdection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/network_info.dart';
import 'product_injection.dart';
import 'category_injection.dart';
import 'wishlist_injection.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // 🌐 CORE & EXTERNAL DEPENDENCIES
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => InternetConnection());
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(internetConnection: sl()),
  );

  // Shared Preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Register feature dependencies
  registerProductDependencies(sl);
  registerCategoryDependencies(sl);
  registerWishlistDependencies(sl);
  authRegisterDependencies(sl);
}
