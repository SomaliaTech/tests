import 'package:equatable/equatable.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAnalyticsEvent extends AnalyticsEvent {
  final String period;
  const LoadAnalyticsEvent({this.period = 'week'});

  @override
  List<Object?> get props => [period];
}

class ChangeAnalyticsPeriodEvent extends AnalyticsEvent {
  final String period;
  const ChangeAnalyticsPeriodEvent(this.period);

  @override
  List<Object?> get props => [period];
}
