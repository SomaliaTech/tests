import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/order/domain/usecases/get_order_details.dart';
import 'order_details_event.dart';
import 'order_details_state.dart';

class OrderDetailsBloc extends Bloc<OrderDetailsEvent, OrderDetailsState> {
  final GetOrderDetails getOrderDetails;
  final StorageService storageService;

  OrderDetailsBloc({
    required this.getOrderDetails,
    required this.storageService,
  }) : super(OrderDetailsInitial()) {
    on<LoadOrderDetailsEvent>(_onLoadOrderDetails);
    on<RefreshOrderDetailsEvent>(_onRefreshOrderDetails);
  }

  Future<void> _onLoadOrderDetails(
    LoadOrderDetailsEvent event,
    Emitter<OrderDetailsState> emit,
  ) async {
    emit(OrderDetailsLoading());

    // ✅ Get admin status from storage
    final isAdmin = await storageService.getIsAdmin();
    final isSuperAdmin = await storageService.getIsSuperAdmin();

    print(
      '🔍 [OrderDetailsBloc] isAdmin: $isAdmin, isSuperAdmin: $isSuperAdmin',
    );

    final result = await getOrderDetails(
      event.orderId,
      isAdmin: isAdmin,
      isSuperAdmin: isSuperAdmin,
    );

    result.fold(
      (failure) => emit(OrderDetailsError(failure.message)),
      (order) => emit(OrderDetailsLoaded(order)),
    );
  }

  Future<void> _onRefreshOrderDetails(
    RefreshOrderDetailsEvent event,
    Emitter<OrderDetailsState> emit,
  ) async {
    final isAdmin = await storageService.getIsAdmin();
    final isSuperAdmin = await storageService.getIsSuperAdmin();

    final result = await getOrderDetails(
      event.orderId,
      isAdmin: isAdmin,
      isSuperAdmin: isSuperAdmin,
    );

    result.fold(
      (failure) => emit(OrderDetailsError(failure.message)),
      (order) => emit(OrderDetailsLoaded(order)),
    );
  }
}
