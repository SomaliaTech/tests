// lib/features/order/presentation/bloc/order_state.dart
import 'package:equatable/equatable.dart';
import 'package:mobile/features/order/domain/entities/order.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderCreated extends OrderState {
  final Map<String, dynamic> order; // ✅ Changed to Map

  const OrderCreated(this.order);

  @override
  List<Object?> get props => [order];
}

class PaymentProcessed extends OrderState {
  final Map<String, dynamic> paymentResult;

  const PaymentProcessed(this.paymentResult);

  @override
  List<Object?> get props => [paymentResult];
}

class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}
