import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/admin/domain/repositories/analytics_repository.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository repository;

  AnalyticsBloc({required this.repository}) : super(AnalyticsInitial()) {
    on<LoadAnalyticsEvent>(_onLoad);
    on<ChangeAnalyticsPeriodEvent>(_onChangePeriod);
  }

  Future<void> _onLoad(
    LoadAnalyticsEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    final result = await repository.getAllAnalytics(period: event.period);
    result.fold(
      (failure) => emit(AnalyticsError(failure.message)),
      (data) => emit(AnalyticsLoaded(data: data, period: event.period)),
    );
  }

  Future<void> _onChangePeriod(
    ChangeAnalyticsPeriodEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    final result = await repository.getAllAnalytics(period: event.period);
    result.fold(
      (failure) => emit(AnalyticsError(failure.message)),
      (data) => emit(AnalyticsLoaded(data: data, period: event.period)),
    );
  }
}
