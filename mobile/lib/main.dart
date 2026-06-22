import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/common/widgets/navigation.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/dashborad/dashboard_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/dashborad/dashboard_event.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_bloc.dart';

import 'package:mobile/features/order/presentation/bloc/order_bloc.dart';
import 'package:mobile/features/order/presentation/bloc/order_details_bloc.dart';
import 'package:mobile/features/order/presentation/bloc/order_history_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/address_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/category_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/product_bloc.dart';
import 'package:mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:mobile/features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'package:toastification/toastification.dart';
import 'core/services/injection_container.dart';
import 'core/theme/theme.dart';
import 'features/auth/presentation/screens/phone_input_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          BlocProvider(create: (context) => sl<TrackingBloc>()), // Only once
          BlocProvider(create: (context) => sl<OrderHistoryBloc>()),
          BlocProvider(create: (context) => sl<AddressBloc>()),
          BlocProvider(create: (context) => sl<OrderDetailsBloc>()),
          BlocProvider(create: (context) => sl<AdminBloc>()),
          BlocProvider(create: (context) => sl<DashboardBloc>()),
        ],
        child: MaterialApp(
          title: 'HALDOOR',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: BlocBuilder<AuthBloc, AuthState>(
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
          ),
          routes: {'/home': (context) => const MainNavigationScreen()},
        ),
      ),
    );
  }
}
