import 'package:flutter_bloc/flutter_bloc.dart';
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

  NotificationsBloc({
    required this.getNotifications,
    required this.markAsRead,
    required this.markAllAsRead,
    required this.deleteNotification,
    required this.clearAllNotifications,
  }) : super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationAsRead>(_onMarkAsRead); // Changed
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead); // Changed
    on<DeleteNotificationEvent>(_onDeleteNotification); // Changed
    on<ClearAllNotificationsEvent>(_onClearAllNotifications); // Changed
    on<SetNotificationFilter>(_onSetFilter);
    on<RefreshNotifications>(_onRefreshNotifications);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());

    final result = await getNotifications();
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
    MarkNotificationAsRead event, // Changed
    Emitter<NotificationsState> emit,
  ) async {
    final result = await markAsRead(event.id);
    result.fold(
      (failure) => emit(NotificationsError(failure.message)),
      (_) => add(LoadNotifications()),
    );
  }

  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsRead event, // Changed
    Emitter<NotificationsState> emit,
  ) async {
    final result = await markAllAsRead();
    result.fold((failure) => emit(NotificationsError(failure.message)), (_) {
      add(LoadNotifications());
      emit(const NotificationsSuccess('All notifications marked as read'));
    });
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event, // Changed
    Emitter<NotificationsState> emit,
  ) async {
    final result = await deleteNotification(event.id);
    result.fold(
      (failure) => emit(NotificationsError(failure.message)),
      (_) => add(LoadNotifications()),
    );
  }

  Future<void> _onClearAllNotifications(
    ClearAllNotificationsEvent event, // Changed
    Emitter<NotificationsState> emit,
  ) async {
    final result = await clearAllNotifications();
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
}
