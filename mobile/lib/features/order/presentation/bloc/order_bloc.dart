import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/order/domain/usecases/create_order.dart';
import 'package:mobile/features/order/domain/usecases/process_payment.dart';

import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final CreateOrder createOrder;
  final ProcessPayment processPayment;

  OrderBloc({required this.createOrder, required this.processPayment})
    : super(OrderInitial()) {
    on<CreateOrderEvent>(_onCreateOrder);
    on<ProcessPaymentEvent>(_onProcessPayment);
  }

  Future<void> _onCreateOrder(
    CreateOrderEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    print('📦 Creating order with data: ${event.orderData}');

    final result = await createOrder(event.orderData);

    result.fold(
      (failure) {
        print('❌ Order creation failed: ${failure.message}');
        print('❌ Failure type: ${failure.runtimeType}');
        emit(OrderError(failure.message));
      },
      (order) {
        print('✅ Order created successfully: ${order.id}');
        emit(OrderCreated(order));
      },
    );
  }

  Future<void> _onProcessPayment(
    ProcessPaymentEvent event,
    Emitter<OrderState> emit,
  ) async {
    // Note: We don't emit Loading here again if we want to keep the spinner from the previous step
    // But typically it's safer to emit loading if there's a network delay for payment
    emit(OrderLoading());

    final result = await processPayment(
      event.orderId,
      event.paymentMethod,
      phoneNumber: event.phoneNumber,
    );
    result.fold(
      (failure) => emit(OrderError(failure.message)),
      (paymentResult) => emit(PaymentProcessed(paymentResult)),
    );
  }

  @override
  void onChange(Change<OrderState> change) {
    super.onChange(change);
    print(change);
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    print("OrderBloc Error: $error \nStackTrace: $stackTrace");
  }
}
