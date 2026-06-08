import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/common/widgets/navigation.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/core/services/injection_container.dart'; // 🟢 Import your new injector
import 'package:mobile/features/product/presentation/blocs/product_bloc.dart';

void main() async {
  // Ensure framework channels are initialized before kicking off dependencies
  WidgetsFlutterBinding.ensureInitialized();

  // 🟢 Run the dependency tree construction
  await initDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // 🟢 GetIt automatically resolves the Bloc and all its underlying requirements!
        BlocProvider(create: (context) => sl<ProductBloc>()),
      ],
      child: MaterialApp(
        title: 'HALDOOR',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
