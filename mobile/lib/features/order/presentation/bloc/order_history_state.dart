import 'package:equatable/equatable.dart';
import '../../domain/entities/order_history.dart';

abstract class OrderHistoryState extends Equatable {
  const OrderHistoryState();
  @override
  List<Object?> get props => [];
}

class OrderHistoryInitial extends OrderHistoryState {}

class OrderHistoryLoading extends OrderHistoryState {}

class OrderHistoryLoaded extends OrderHistoryState {
  final List<OrderHistory> orders;
  const OrderHistoryLoaded(this.orders);
  @override
  List<Object?> get props => [orders];
}

class OrderHistoryDetailLoaded extends OrderHistoryState {
  final OrderHistory order;
  const OrderHistoryDetailLoaded(this.order);
  @override
  List<Object?> get props => [order];
}

class OrderHistoryError extends OrderHistoryState {
  final String message;
  const OrderHistoryError(this.message);
  @override
  List<Object?> get props => [message];
}
