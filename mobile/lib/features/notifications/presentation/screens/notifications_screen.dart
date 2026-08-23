import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:mobile/features/notifications/presentation/bloc/notifications_state.dart';
import 'notifications_view.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthChecking) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2ED573)),
            ),
          );
        }

        // ✅ Use the existing NotificationsBloc from the parent MultiBlocProvider
        // Don't create a new one - just dispatch the load event
        final notificationsBloc = context.read<NotificationsBloc>();

        // ✅ Only dispatch if not already loaded
        if (notificationsBloc.state is! NotificationsLoaded) {
          notificationsBloc.add(LoadNotifications());
        }

        return const NotificationsView();
      },
    );
  }
}
