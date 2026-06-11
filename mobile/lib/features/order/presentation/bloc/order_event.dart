import 'package:equatable/equatable.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();
  @override
  List<Object?> get props => [];
}

class CreateOrderEvent extends OrderEvent {
  final Map<String, dynamic> orderData;
  const CreateOrderEvent(this.orderData);
  @override
  List<Object?> get props => [orderData];
}

class ProcessPaymentEvent extends OrderEvent {
  final String orderId;
  final String paymentMethod;
  final String? phoneNumber;
  const ProcessPaymentEvent({
    required this.orderId,
    required this.paymentMethod,
    this.phoneNumber,
  });
  @override
  List<Object?> get props => [orderId, paymentMethod, phoneNumber];
}
