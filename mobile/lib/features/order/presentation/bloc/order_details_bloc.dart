import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/order/domain/usecases/get_order_details.dart';
import 'order_details_event.dart';
import 'order_details_state.dart';

class OrderDetailsBloc extends Bloc<OrderDetailsEvent, OrderDetailsState> {
  final GetOrderDetails getOrderDetails;

  OrderDetailsBloc({required this.getOrderDetails})
    : super(OrderDetailsInitial()) {
    on<LoadOrderDetailsEvent>(_onLoadOrderDetails);
    on<RefreshOrderDetailsEvent>(_onRefreshOrderDetails);
  }

  Future<void> _onLoadOrderDetails(
    LoadOrderDetailsEvent event,
    Emitter<OrderDetailsState> emit,
  ) async {
    emit(OrderDetailsLoading());
    final result = await getOrderDetails(event.orderId);
    result.fold(
      (failure) => emit(OrderDetailsError(failure.message)),
      (order) => emit(OrderDetailsLoaded(order)),
    );
  }

  Future<void> _onRefreshOrderDetails(
    RefreshOrderDetailsEvent event,
    Emitter<OrderDetailsState> emit,
  ) async {
    final result = await getOrderDetails(event.orderId);
    result.fold(
      (failure) => emit(OrderDetailsError(failure.message)),
      (order) => emit(OrderDetailsLoaded(order)),
    );
  }
}
