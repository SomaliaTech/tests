import 'package:equatable/equatable.dart';
import 'package:mobile/features/admin/domain/entities/admin_revenue_entity.dart';

abstract class RevenueState extends Equatable {
  const RevenueState();
  @override
  List<Object?> get props => [];
}

class RevenueInitial extends RevenueState {}

// Summary States
class RevenueSummaryLoading extends RevenueState {}

class RevenueSummaryLoaded extends RevenueState {
  final AdminRevenueSummaryEntity summary;
  final String period;

  const RevenueSummaryLoaded(this.summary, this.period);

  @override
  List<Object?> get props => [summary, period];
}

class RevenueSummaryError extends RevenueState {
  final String message;
  const RevenueSummaryError(this.message);
  @override
  List<Object?> get props => [message];
}

// List States
class RevenueListLoading extends RevenueState {}

class RevenueListLoaded extends RevenueState {
  final List<AdminRevenueListEntity> revenueList;
  final int total;

  const RevenueListLoaded(this.revenueList, this.total);

  @override
  List<Object?> get props => [revenueList, total];
}

class RevenueListError extends RevenueState {
  final String message;
  const RevenueListError(this.message);
  @override
  List<Object?> get props => [message];
}

// Details States
class RevenueDetailsLoading extends RevenueState {}

class RevenueDetailsLoaded extends RevenueState {
  final AdminRevenueEntity revenue;
  const RevenueDetailsLoaded(this.revenue);
  @override
  List<Object?> get props => [revenue];
}

class RevenueDetailsError extends RevenueState {
  final String message;
  const RevenueDetailsError(this.message);
  @override
  List<Object?> get props => [message];
}
