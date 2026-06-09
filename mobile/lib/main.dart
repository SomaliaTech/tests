// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:toastification/toastification.dart';
import 'core/services/injection_container.dart'; // Correct import path
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
          // Add other blocs here if needed
          // BlocProvider(create: (context) => sl<ProductBloc>()),
          // BlocProvider(create: (context) => sl<WishlistBloc>()),
        ],
        child: MaterialApp(
          title: 'HALDOOR',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: BlocBuilder<AuthBloc, AuthState>(
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
                return PhoneInputScreen();
              }
            },
          ),
          routes: {'/home': (context) => const MainNavigationScreen()},
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Home'), backgroundColor: Colors.white),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 80, color: Color(0xFF2ED573)),
            const SizedBox(height: 20),
            const Text(
              'Welcome to HALDOOR!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(const LogoutEvent());
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
