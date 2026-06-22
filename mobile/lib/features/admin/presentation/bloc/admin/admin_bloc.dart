import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin/admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository repository;

  AdminBloc({required this.repository}) : super(AdminInitial()) {
    on<FetchAdminStatsEvent>(_onFetchStats);
    on<FetchAllOrdersEvent>(_onFetchOrders);
    on<UpdateOrderStatusEvent>(_onUpdateStatus);
  }

  Future<void> _onFetchStats(
    FetchAdminStatsEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminStatsLoading());
    try {
      final stats = await repository.getAdminStats();
      emit(AdminStatsLoaded(stats));
    } catch (e) {
      emit(AdminStatsError(e.toString()));
    }
  }

  Future<void> _onFetchOrders(
    FetchAllOrdersEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminOrdersLoading());
    try {
      final orders = await repository.getAllOrders(event.search);
      emit(AdminOrdersLoaded(orders));
    } catch (e) {
      emit(AdminOrdersError(e.toString()));
    }
  }

  Future<void> _onUpdateStatus(
    UpdateOrderStatusEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminStatusUpdating());
    try {
      await repository.updateOrderStatus(event.orderId, event.newStatus);

      // ✅ Include both message AND newStatus
      emit(
        AdminStatusUpdated(
          message: 'Order status updated successfully',
          newStatus: event.newStatus,
          orderId: event.orderId, // Add this if your state requires it
        ),
      );

      // Refresh orders after update
      add(const FetchAllOrdersEvent());
    } catch (e) {
      emit(AdminStatusUpdateError(e.toString()));
    }
  }
}
