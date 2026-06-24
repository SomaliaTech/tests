import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/admin/domain/repositories/dashboard_repository.dart';
import 'package:mobile/features/admin/presentation/bloc/dashborad/dashboard_event.dart';
import 'package:mobile/features/admin/presentation/bloc/dashborad/dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository repository;

  DashboardBloc({required this.repository}) : super(DashboardInitial()) {
    on<LoadDashboardDataEvent>(_onLoadDashboardData);
    on<ChangePeriodEvent>(_onChangePeriod);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardDataEvent event,
    Emitter<DashboardState> emit,
  ) async {
    print('🎯 [BLoC] LoadDashboardDataEvent for period: ${event.period}');
    emit(DashboardLoading());
    try {
      final stopwatch = Stopwatch()..start();
      final data = await repository.getAllDashboardData(event.period);
      print('✅ [BLoC] Data loaded in ${stopwatch.elapsedMilliseconds}ms');
      emit(data);
    } catch (e, stackTrace) {
      print('❌ [BLoC] Error: $e');
      print('📚 [BLoC] Stack trace: $stackTrace');
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onChangePeriod(
    ChangePeriodEvent event,
    Emitter<DashboardState> emit,
  ) async {
    print('🎯 [BLoC] ChangePeriodEvent for period: ${event.period}');
    emit(DashboardLoading());
    try {
      final stopwatch = Stopwatch()..start();
      final data = await repository.getAllDashboardData(event.period);
      print('✅ [BLoC] Data loaded in ${stopwatch.elapsedMilliseconds}ms');
      emit(data);
    } catch (e, stackTrace) {
      print('❌ [BLoC] Error: $e');
      print('📚 [BLoC] Stack trace: $stackTrace');
      emit(DashboardError(e.toString()));
    }
  }
}
