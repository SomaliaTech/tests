import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboardDataEvent extends DashboardEvent {
  final String period;
  const LoadDashboardDataEvent({this.period = 'week'}); // ✅ Named parameter

  @override
  List<Object?> get props => [period];
}

class ChangePeriodEvent extends DashboardEvent {
  final String period;
  const ChangePeriodEvent({required this.period}); // ✅ Named parameter

  @override
  List<Object?> get props => [period];
}
