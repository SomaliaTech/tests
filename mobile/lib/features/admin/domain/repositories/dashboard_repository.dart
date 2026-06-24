import 'package:mobile/features/admin/presentation/bloc/dashborad/dashboard_state.dart';

abstract class DashboardRepository {
  Future<DashboardLoaded> getAllDashboardData(String period);
}
