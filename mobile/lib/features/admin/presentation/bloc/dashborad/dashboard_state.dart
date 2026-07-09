import 'package:equatable/equatable.dart';
import 'package:mobile/features/admin/domain/entities/chart_data_entity.dart';
import 'package:mobile/features/admin/domain/entities/dashboard_stats_entity.dart';
import 'package:mobile/features/admin/domain/entities/device_traffic_entity.dart';
import 'package:mobile/features/admin/domain/entities/location_traffic_entity.dart';
import 'package:mobile/features/admin/domain/entities/product_traffic_entity.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStatsEntity stats;
  final List<ChartDataEntity> usersChartData;
  final List<ChartDataEntity> revenueChartData;
  final List<DeviceTrafficEntity> deviceTraffic;
  final List<LocationTrafficEntity> locationTraffic;
  final List<ProductTrafficEntity> productTraffic;
  final String period;

  const DashboardLoaded({
    required this.stats,
    required this.usersChartData,
    required this.revenueChartData,
    required this.deviceTraffic,
    required this.locationTraffic,
    required this.productTraffic,
    required this.period,
  });

  @override
  List<Object?> get props => [
    stats,
    usersChartData,
    revenueChartData,
    deviceTraffic,
    locationTraffic,
    productTraffic,
    period,
  ];
}

// In dashboard_state.dart
class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
