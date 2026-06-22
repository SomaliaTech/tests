import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/admin/data/datasources/dashboard_remote_data_source.dart';
import 'package:mobile/features/admin/domain/entities/chart_data_entity.dart';
import 'package:mobile/features/admin/domain/entities/dashboard_stats_entity.dart';
import 'package:mobile/features/admin/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DashboardStatsEntity> getDashboardStats(String period) async {
    try {
      return await remoteDataSource.getDashboardStats(period);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<List<ChartDataEntity>> getUsersChartData(String period) async {
    try {
      final models = await remoteDataSource.getUsersChartData(period);
      return models.cast<ChartDataEntity>(); // ✅ Cast to entity list
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<List<DeviceTrafficEntity>> getDeviceTraffic() async {
    try {
      final models = await remoteDataSource.getDeviceTraffic();
      return models.cast<DeviceTrafficEntity>(); // ✅ Cast to entity list
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<List<LocationTrafficEntity>> getLocationTraffic() async {
    try {
      final models = await remoteDataSource.getLocationTraffic();
      return models.cast<LocationTrafficEntity>(); // ✅ Cast to entity list
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<List<ProductTrafficEntity>> getProductTraffic(String period) async {
    try {
      final models = await remoteDataSource.getProductTraffic(period);
      return models.cast<ProductTrafficEntity>(); // ✅ Cast to entity list
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<List<ChartDataEntity>> getRevenueChart(String period) async {
    try {
      final models = await remoteDataSource.getRevenueChart(period);
      return models.cast<ChartDataEntity>(); // ✅ Cast to entity list
    } on ServerException {
      rethrow;
    }
  }
}
