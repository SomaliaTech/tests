import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/category_bloc.dart';
import 'package:toastification/toastification.dart';
import 'core/services/injection_container.dart';
import 'core/theme/theme.dart';
import 'features/product/presentation/blocs/product_bloc.dart';
import 'features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'core/common/widgets/navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies FIRST
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
          BlocProvider(create: (context) => sl<ProductBloc>()),
          BlocProvider(create: (context) => sl<WishlistBloc>()),
          BlocProvider(create: (context) => sl<CategoryBloc>()),
        ],
        child: MaterialApp(
          title: 'HALDOOR',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const MainNavigationScreen(),
        ),
      ),
    );
  }
}
