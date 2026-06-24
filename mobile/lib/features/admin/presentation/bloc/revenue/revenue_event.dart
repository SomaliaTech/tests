import 'package:equatable/equatable.dart';

abstract class RevenueEvent extends Equatable {
  const RevenueEvent();
  @override
  List<Object?> get props => [];
}

class FetchRevenueSummaryEvent extends RevenueEvent {
  final String period;
  const FetchRevenueSummaryEvent({this.period = 'week'});

  @override
  List<Object?> get props => [period];
}

class FetchAllRevenueEvent extends RevenueEvent {
  final String? search;
  final String? paymentMethod;
  final String? status;
  final int limit;
  final int offset;

  const FetchAllRevenueEvent({
    this.search,
    this.paymentMethod,
    this.status,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [search, paymentMethod, status, limit, offset];
}

class FetchRevenueDetailsEvent extends RevenueEvent {
  final String orderId;
  const FetchRevenueDetailsEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
