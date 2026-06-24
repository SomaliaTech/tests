import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mobile/core/common/widgets/navigation.dart';
import 'package:mobile/core/common/widgets/no_internet_screen.dart';
import 'package:mobile/core/services/injection_container.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_product/admin_product_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/dashborad/dashboard_bloc.dart';
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
import 'package:mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:mobile/features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart'; // 🚨 ADD IMPORT
// ... (keep all your other bloc imports) ...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

// 🚨 ADD: with WidgetsBindingObserver
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final InternetConnection _internetConnection = InternetConnection();
  late Future<bool> _initialConnectionCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 🚨 ADD THIS
    _initialConnectionCheck = _internetConnection.hasInternetAccess;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 🚨 ADD THIS
    super.dispose();
  }

  // 🚨 ADD THIS METHOD: Reconnect socket when app comes to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final authState = sl<AuthBloc>().state;
      if (authState is Authenticated ||
          authState is OtpVerified ||
          authState is ProfileCompleted) {
        sl<ChatSocketService>().connect();
      }
    }
  }

  void _checkConnection() {
    setState(() {
      _initialConnectionCheck = _internetConnection.hasInternetAccess;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MultiBlocProvider(
        providers: [
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
          BlocProvider(create: (context) => sl<NotificationsBloc>()),
          BlocProvider(create: (context) => sl<ConversationsBloc>()),
          BlocProvider(create: (context) => sl<ChatRoomBloc>()),
          Provider<StorageService>.value(value: sl<StorageService>()),
        ],
        child: MaterialApp(
          title: 'HALDOOR',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: FutureBuilder<bool>(
            future: _initialConnectionCheck,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF2ED573),
                      ),
                    ),
                  ),
                );
              }

              final hasInternet = snapshot.data ?? false;

              if (!hasInternet) {
                return NoInternetScreen(onRetry: _checkConnection);
              }

              return StreamBuilder<InternetStatus>(
                stream: _internetConnection.onStatusChange,
                builder: (context, streamSnapshot) {
                  final currentStatus = streamSnapshot.data;

                  if (currentStatus == InternetStatus.disconnected) {
                    return NoInternetScreen(onRetry: _checkConnection);
                  }

                  return BlocBuilder<AuthBloc, AuthState>(
                    buildWhen: (previous, current) =>
                        current is AuthChecking ||
                        current is Authenticated ||
                        current is Unauthenticated,
                    builder: (context, state) {
                      if (state is AuthChecking) {
                        return const Scaffold(
                          backgroundColor: Colors.white,
                          body: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2ED573),
                              ),
                            ),
                          ),
                        );
                      } else if (state is Authenticated) {
                        return const MainNavigationScreen();
                      } else {
                        return const PhoneInputScreen();
                      }
                    },
                  );
                },
              );
            },
          ),
          routes: {'/home': (context) => const MainNavigationScreen()},
        ),
      ),
    );
  }
}
