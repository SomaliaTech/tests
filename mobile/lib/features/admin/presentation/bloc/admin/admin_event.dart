import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();
  @override
  List<Object?> get props => [];
}

class FetchAdminStatsEvent extends AdminEvent {}

class FetchAllOrdersEvent extends AdminEvent {
  final String? search;
  const FetchAllOrdersEvent({this.search});

  @override
  List<Object?> get props => [search];
}

class UpdateOrderStatusEvent extends AdminEvent {
  final String orderId;
  final String newStatus;
  const UpdateOrderStatusEvent(this.orderId, this.newStatus);

  @override
  List<Object?> get props => [orderId, newStatus];
}
