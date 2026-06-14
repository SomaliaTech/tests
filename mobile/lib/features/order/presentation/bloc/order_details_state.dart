import 'package:equatable/equatable.dart';
import '../../domain/entities/order_details.dart';

abstract class OrderDetailsState extends Equatable {
  const OrderDetailsState();
  @override
  List<Object?> get props => [];
}

class OrderDetailsInitial extends OrderDetailsState {}

class OrderDetailsLoading extends OrderDetailsState {}

class OrderDetailsLoaded extends OrderDetailsState {
  final OrderDetails order;
  const OrderDetailsLoaded(this.order);
  @override
  List<Object?> get props => [order];
}

class OrderDetailsError extends OrderDetailsState {
  final String message;
  const OrderDetailsError(this.message);
  @override
  List<Object?> get props => [message];
}
