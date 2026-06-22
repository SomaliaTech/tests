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
    emit(DashboardLoading());
    try {
      final stats = await repository.getDashboardStats(event.period);
      final usersChartData = await repository.getUsersChartData(event.period);
      final revenueChartData = await repository.getRevenueChart(event.period);
      final deviceTraffic = await repository.getDeviceTraffic();
      final locationTraffic = await repository.getLocationTraffic();
      final productTraffic = await repository.getProductTraffic(event.period);

      emit(
        DashboardLoaded(
          stats: stats,
          usersChartData: usersChartData,
          revenueChartData: revenueChartData,
          deviceTraffic: deviceTraffic,
          locationTraffic: locationTraffic,
          productTraffic: productTraffic,
          period: event.period,
        ),
      );
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onChangePeriod(
    ChangePeriodEvent event,
    Emitter<DashboardState> emit,
  ) async {
    // ✅ Don't emit loading state - directly fetch and update
    try {
      // Get current state to keep data if needed
      final currentState = state;

      final stats = await repository.getDashboardStats(event.period);
      final usersChartData = await repository.getUsersChartData(event.period);
      final revenueChartData = await repository.getRevenueChart(event.period);
      final deviceTraffic = await repository.getDeviceTraffic();
      final locationTraffic = await repository.getLocationTraffic();
      final productTraffic = await repository.getProductTraffic(event.period);

      // ✅ Directly emit loaded state without loading state
      emit(
        DashboardLoaded(
          stats: stats,
          usersChartData: usersChartData,
          revenueChartData: revenueChartData,
          deviceTraffic: deviceTraffic,
          locationTraffic: locationTraffic,
          productTraffic: productTraffic,
          period: event.period,
        ),
      );
    } catch (e) {
      // If error, keep current state or show error
      if (state is DashboardLoaded) {
        // Keep showing current data
        emit(state);
      } else {
        emit(DashboardError(e.toString()));
      }
    }
  }
}
