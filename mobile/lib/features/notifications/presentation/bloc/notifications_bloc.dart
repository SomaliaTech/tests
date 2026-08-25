import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/features/notifications/data/datasources/local/notifications_local_datasource.dart';
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
  bool _isLoading = false;
  DateTime? _lastFetchTime;
  final ChatSocketService _socketService = GetIt.instance<ChatSocketService>();
  StreamSubscription? _notificationSub;
  static const Duration _minFetchInterval = Duration(seconds: 30);
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
    if (_isLoading) return;
    _isLoading = true;

    final currentState = state;
    final isSilentRefresh = currentState is NotificationsLoaded;

    if (!isSilentRefresh) {
      emit(NotificationsLoading());
    }

    // ✅ Pass forceRefresh when explicitly loading
    final result = await getNotifications.call(
      forceRefresh: event.forceRefresh,
    );
    _isLoading = false;

    result.fold(
      (failure) {
        if (!isSilentRefresh) {
          emit(NotificationsError(failure.message));
        }
      },
      (notifications) {
        emit(
          NotificationsLoaded(
            notifications: notifications,
            currentFilter: isSilentRefresh
                ? (currentState as NotificationsLoaded).currentFilter
                : NotificationFilter.all,
          ),
        );
      },
    );
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    // ✅ Update local state immediately
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      final updatedNotifications = currentState.notifications.map((n) {
        if (n.id == event.id) {
          return n.copyWith(read: true);
        }
        return n;
      }).toList();

      emit(
        NotificationsLoaded(
          notifications: updatedNotifications,
          currentFilter: currentState.currentFilter,
        ),
      );
    }

    // ✅ Then update backend in background
    final result = await markAsRead.call(event.id);
    result.fold(
      (failure) {
        // If backend fails, revert local change
        if (state is NotificationsLoaded) {
          final currentState = state as NotificationsLoaded;
          final revertedNotifications = currentState.notifications.map((n) {
            if (n.id == event.id) {
              return n.copyWith(read: false);
            }
            return n;
          }).toList();

          emit(
            NotificationsLoaded(
              notifications: revertedNotifications,
              currentFilter: currentState.currentFilter,
            ),
          );
        }
        emit(NotificationsError(failure.message));
      },
      (_) {
        // ✅ Backend updated successfully
        // Also update cache
        if (state is NotificationsLoaded) {
          final currentState = state as NotificationsLoaded;
          // Update cache in background
          _updateCache(currentState.notifications);
        }
      },
    );
  }

  // ✅ Helper to update cache
  Future<void> _updateCache(List<NotificationEntity> notifications) async {
    try {
      final localDataSource = GetIt.instance<NotificationsLocalDataSource>();
      await localDataSource.cacheNotifications(notifications);
    } catch (e) {
      debugPrint('⚠️ Failed to update cache: $e');
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    // ✅ Update local state immediately
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      final updatedNotifications = currentState.notifications.map((n) {
        return n.copyWith(read: true);
      }).toList();

      emit(
        NotificationsLoaded(
          notifications: updatedNotifications,
          currentFilter: currentState.currentFilter,
        ),
      );
    }

    // ✅ Then update backend
    final result = await markAllAsRead.call();
    result.fold((failure) => emit(NotificationsError(failure.message)), (_) {
      if (state is NotificationsLoaded) {
        _updateCache((state as NotificationsLoaded).notifications);
      }
      emit(const NotificationsSuccess('All notifications marked as read'));
    });
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    // ✅ Update local state immediately
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      final updatedNotifications = currentState.notifications
          .where((n) => n.id != event.id)
          .toList();

      emit(
        NotificationsLoaded(
          notifications: updatedNotifications,
          currentFilter: currentState.currentFilter,
        ),
      );
    }

    // ✅ Then update backend
    final result = await deleteNotification.call(event.id);
    result.fold((failure) => emit(NotificationsError(failure.message)), (_) {
      if (state is NotificationsLoaded) {
        _updateCache((state as NotificationsLoaded).notifications);
      }
    });
  }

  Future<void> _onClearAllNotifications(
    ClearAllNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    // ✅ Clear local state immediately
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      emit(
        NotificationsLoaded(
          notifications: [],
          currentFilter: currentState.currentFilter,
        ),
      );
    }

    // ✅ Then update backend
    final result = await clearAllNotifications.call();
    result.fold((failure) => emit(NotificationsError(failure.message)), (_) {
      _updateCache([]);
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
