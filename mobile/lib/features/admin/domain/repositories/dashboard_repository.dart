import 'package:mobile/features/admin/domain/entities/chart_data_entity.dart';
import 'package:mobile/features/admin/domain/entities/dashboard_stats_entity.dart';

abstract class DashboardRepository {
  Future<DashboardStatsEntity> getDashboardStats(String period);
  Future<List<ChartDataEntity>> getUsersChartData(String period);
  Future<List<DeviceTrafficEntity>> getDeviceTraffic();
  Future<List<LocationTrafficEntity>> getLocationTraffic();
  Future<List<ProductTrafficEntity>> getProductTraffic(String period);
  Future<List<ChartDataEntity>> getRevenueChart(String period);
}
