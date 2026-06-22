import 'package:equatable/equatable.dart';

class ChartDataEntity extends Equatable {
  final String date;
  final double value;
  final int count;

  const ChartDataEntity({
    required this.date,
    required this.value,
    required this.count,
  });

  @override
  List<Object?> get props => [date, value, count];
}

class DeviceTrafficEntity extends Equatable {
  final String device;
  final int value;
  final String color;

  const DeviceTrafficEntity({
    required this.device,
    required this.value,
    required this.color,
  });

  @override
  List<Object?> get props => [device, value, color];
}

class LocationTrafficEntity extends Equatable {
  final String location;
  final int users;
  final String percentage;

  const LocationTrafficEntity({
    required this.location,
    required this.users,
    required this.percentage,
  });

  @override
  List<Object?> get props => [location, users, percentage];
}

class ProductTrafficEntity extends Equatable {
  final String productId;
  final String productName;
  final int views;

  const ProductTrafficEntity({
    required this.productId,
    required this.productName,
    required this.views,
  });

  @override
  List<Object?> get props => [productId, productName, views];
}
