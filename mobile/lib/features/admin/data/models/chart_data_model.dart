import 'package:mobile/features/admin/domain/entities/chart_data_entity.dart';

class ChartDataModel extends ChartDataEntity {
  const ChartDataModel({
    required super.date,
    required super.value,
    required super.count,
  });

  factory ChartDataModel.fromJson(Map<String, dynamic> json) {
    return ChartDataModel(
      date: json['date'] ?? '',
      value: (json['revenue'] ?? json['users'] ?? 0).toDouble(),
      count: json['orders'] ?? json['users'] ?? 0,
    );
  }
}

class DeviceTrafficModel extends DeviceTrafficEntity {
  const DeviceTrafficModel({
    required super.device,
    required super.value,
    required super.color,
  });

  factory DeviceTrafficModel.fromJson(Map<String, dynamic> json) {
    return DeviceTrafficModel(
      device: json['device'] ?? '',
      value: json['value'] ?? 0,
      color: json['color'] ?? '#2ED573',
    );
  }
}

class LocationTrafficModel extends LocationTrafficEntity {
  const LocationTrafficModel({
    required super.location,
    required super.users,
    required super.percentage,
  });

  factory LocationTrafficModel.fromJson(Map<String, dynamic> json) {
    return LocationTrafficModel(
      location: json['location'] ?? '',
      users: json['users'] ?? 0,
      percentage: json['percentage'] ?? '0.0',
    );
  }
}

class ProductTrafficModel extends ProductTrafficEntity {
  const ProductTrafficModel({
    required super.productId,
    required super.productName,
    required super.views,
  });

  factory ProductTrafficModel.fromJson(Map<String, dynamic> json) {
    return ProductTrafficModel(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      views: json['views'] ?? 0,
    );
  }
}
