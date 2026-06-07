import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_local_datasource.dart';
import 'package:mobile/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:mobile/features/notifications/domain/usecases/clear_all_notifications.dart';
import 'package:mobile/features/notifications/domain/usecases/delete_notification.dart';
import 'package:mobile/features/notifications/domain/usecases/get_notifications.dart';
import 'package:mobile/features/notifications/domain/usecases/mark_all_as_read.dart';
import 'package:mobile/features/notifications/domain/usecases/mark_as_read.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import 'notifications_view.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localDataSource = NotificationsLocalDataSource();
    final repository = NotificationsRepositoryImpl(
      localDataSource: localDataSource,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<NotificationsBloc>(
          create: (context) => NotificationsBloc(
            getNotifications: GetNotifications(repository),
            markAsRead: MarkAsRead(repository),
            markAllAsRead: MarkAllAsRead(repository),
            deleteNotification: DeleteNotification(repository),
            clearAllNotifications: ClearAllNotifications(repository),
          )..add(LoadNotifications()),
        ),
      ],
      child: const NotificationsView(),
    );
  }
}
