import 'package:equatable/equatable.dart';

abstract class OrderHistoryEvent extends Equatable {
  const OrderHistoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadOrdersEvent extends OrderHistoryEvent {}

class RefreshOrdersEvent extends OrderHistoryEvent {}

class LoadOrderByIdEvent extends OrderHistoryEvent {
  final String orderId;
  const LoadOrderByIdEvent(this.orderId);
  @override
  List<Object?> get props => [orderId];
}
