import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/features/notifications/domain/entities/notification.dart';
import 'package:mobile/features/notifications/domain/usecases/clear_all_notifications.dart';
import 'package:mobile/features/notifications/domain/usecases/delete_notification.dart';
import 'package:mobile/features/notifications/domain/usecases/get_notifications.dart';
import 'package:mobile/features/notifications/domain/usecases/mark_all_as_read.dart';
import 'package:mobile/features/notifications/domain/usecases/mark_as_read.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotifications getNotifications;
  final MarkAsRead markAsRead;
  final MarkAllAsRead markAllAsRead;
  final DeleteNotification deleteNotification;
  final ClearAllNotifications clearAllNotifications;

  final ChatSocketService _socketService = GetIt.instance<ChatSocketService>();
  StreamSubscription? _notificationSub;

  NotificationsBloc({
    required this.getNotifications,
    required this.markAsRead,
    required this.markAllAsRead,
    required this.deleteNotification,
    required this.clearAllNotifications,
  }) : super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
    on<ClearAllNotificationsEvent>(_onClearAllNotifications);
    on<SetNotificationFilter>(_onSetFilter);
    on<RefreshNotifications>(_onRefreshNotifications);

    // ✅ Listen for real-time notifications via WebSocket
    _notificationSub = _socketService.onNewNotification.listen((data) {
      try {
        final notification = NotificationEntity.fromJson(data);
        if (state is NotificationsLoaded) {
          final currentState = state as NotificationsLoaded;
          final updatedList = [notification, ...currentState.notifications];
          emit(
            NotificationsLoaded(
              notifications: updatedList,
              currentFilter: currentState.currentFilter,
            ),
          );
        }
      } catch (e) {
        // Ignore parse errors
      }
    });
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());

    final result = await getNotifications.call();
    result.fold(
      (failure) => emit(NotificationsError(failure.message)),
      (notifications) => emit(
        NotificationsLoaded(
          notifications: notifications,
          currentFilter: NotificationFilter.all,
        ),
      ),
    );
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await markAsRead.call(event.id);
    result.fold(
      (failure) => emit(NotificationsError(failure.message)),
      (_) => add(LoadNotifications()),
    );
  }

  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await markAllAsRead.call();
    result.fold((failure) => emit(NotificationsError(failure.message)), (_) {
      add(LoadNotifications());
      emit(const NotificationsSuccess('All notifications marked as read'));
    });
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await deleteNotification.call(event.id);
    result.fold(
      (failure) => emit(NotificationsError(failure.message)),
      (_) => add(LoadNotifications()),
    );
  }

  Future<void> _onClearAllNotifications(
    ClearAllNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await clearAllNotifications.call();
    result.fold((failure) => emit(NotificationsError(failure.message)), (_) {
      add(LoadNotifications());
      emit(const NotificationsSuccess('All notifications cleared'));
    });
  }

  void _onSetFilter(
    SetNotificationFilter event,
    Emitter<NotificationsState> emit,
  ) {
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      emit(
        NotificationsLoaded(
          notifications: currentState.notifications,
          currentFilter: event.filter,
        ),
      );
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    add(LoadNotifications());
  }

  @override
  Future<void> close() {
    _notificationSub?.cancel();
    return super.close();
  }
}
