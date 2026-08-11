// lib/features/order/presentation/bloc/order_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import 'package:mobile/features/order/domain/usecases/create_order.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final CreateOrder createOrder;

  OrderBloc({required this.createOrder}) : super(OrderInitial()) {
    on<CreateOrderEvent>(_onCreateOrder);
  }

  Future<void> _onCreateOrder(
    CreateOrderEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    developer.log('📦 Creating order with payment: ${event.orderData}');

    final result = await createOrder(event.orderData);

    result.fold(
      (failure) {
        developer.log('❌ Order creation failed: ${failure.message}');
        emit(OrderError(failure.message));
      },
      (responseData) {
        developer.log('✅ Order result: $responseData');

        // ✅ responseData is Map<String, dynamic> from backend
        final message = responseData['message'] as String? ?? '';
        final order = responseData['order'] as Map<String, dynamic>? ?? {};

        if (message.contains('payment processed') || message.contains('PAID')) {
          // Order created AND paid
          emit(
            PaymentProcessed({
              'message': message,
              'orderNumber': order['orderNumber'] ?? '',
              'order': order,
            }),
          );
        } else {
          // Order created but payment pending (cash on delivery)
          emit(OrderCreated(order));
        }
      },
    );
  }

  @override
  void onChange(Change<OrderState> change) {
    super.onChange(change);
    developer.log('OrderBloc change: $change');
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    developer.log('OrderBloc Error: $error');
  }
}
