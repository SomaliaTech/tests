import 'package:equatable/equatable.dart';
import '../../domain/entities/order.dart' as domain;

abstract class OrderState extends Equatable {
  const OrderState();
  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderCreated extends OrderState {
  final domain.DomainOrder order;
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
