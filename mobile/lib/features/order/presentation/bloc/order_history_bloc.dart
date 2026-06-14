import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/order/domain/usecases/get_order_by_id.dart';
import 'package:mobile/features/order/domain/usecases/get_orders.dart';

import 'order_history_event.dart';
import 'order_history_state.dart';

class OrderHistoryBloc extends Bloc<OrderHistoryEvent, OrderHistoryState> {
  final GetOrders getOrders;
  final GetOrderById getOrderById;

  OrderHistoryBloc({required this.getOrders, required this.getOrderById})
    : super(OrderHistoryInitial()) {
    on<LoadOrdersEvent>(_onLoadOrders);
    on<RefreshOrdersEvent>(_onRefreshOrders);
    on<LoadOrderByIdEvent>(_onLoadOrderById);
  }

  Future<void> _onLoadOrders(
    LoadOrdersEvent event,
    Emitter<OrderHistoryState> emit,
  ) async {
    emit(OrderHistoryLoading());
    final result = await getOrders();
    result.fold(
      (failure) => emit(OrderHistoryError(failure.message)),
      (orders) => emit(OrderHistoryLoaded(orders)),
    );
  }

  Future<void> _onRefreshOrders(
    RefreshOrdersEvent event,
    Emitter<OrderHistoryState> emit,
  ) async {
    final result = await getOrders();
    result.fold(
      (failure) => emit(OrderHistoryError(failure.message)),
      (orders) => emit(OrderHistoryLoaded(orders)),
    );
  }

  Future<void> _onLoadOrderById(
    LoadOrderByIdEvent event,
    Emitter<OrderHistoryState> emit,
  ) async {
    emit(OrderHistoryLoading());
    final result = await getOrderById(event.orderId);
    result.fold(
      (failure) => emit(OrderHistoryError(failure.message)),
      (order) => emit(OrderHistoryDetailLoaded(order)),
    );
  }
}
