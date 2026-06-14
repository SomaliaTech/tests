import 'package:equatable/equatable.dart';

abstract class OrderDetailsEvent extends Equatable {
  const OrderDetailsEvent();
  @override
  List<Object?> get props => [];
}

class LoadOrderDetailsEvent extends OrderDetailsEvent {
  final String orderId;
  const LoadOrderDetailsEvent(this.orderId);
  @override
  List<Object?> get props => [orderId];
}

class RefreshOrderDetailsEvent extends OrderDetailsEvent {
  final String orderId;
  const RefreshOrderDetailsEvent(this.orderId);
  @override
  List<Object?> get props => [orderId];
}
