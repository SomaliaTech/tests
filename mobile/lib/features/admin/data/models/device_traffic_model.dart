import 'package:mobile/features/admin/domain/entities/device_traffic_entity.dart';

class DeviceTrafficModel extends DeviceTrafficEntity {
  const DeviceTrafficModel({
    required super.device,
    required super.value,
    super.color,
  });

  factory DeviceTrafficModel.fromJson(Map<String, dynamic> json) {
    return DeviceTrafficModel(
      device: json['device'] ?? '',
      value: json['value'] ?? 0,
      color: json['color'],
    );
  }

  // ✅ Convert to Entity
  DeviceTrafficEntity toEntity() {
    return this;
  }

  Map<String, dynamic> toJson() {
    return {'device': device, 'value': value, 'color': color};
  }
}
