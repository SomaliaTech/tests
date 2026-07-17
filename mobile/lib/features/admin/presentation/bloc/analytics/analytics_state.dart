import 'package:equatable/equatable.dart';
import 'package:mobile/features/admin/domain/entities/analytics_entities.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final AnalyticsDataEntity data;
  final String period;
  final bool isCustomDates;

  const AnalyticsLoaded({
    required this.data,
    this.period = 'week',
    this.isCustomDates = false,
  });

  @override
  List<Object?> get props => [data, period, isCustomDates];
}

class AnalyticsError extends AnalyticsState {
  final String message;
  const AnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}
