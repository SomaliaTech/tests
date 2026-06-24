import 'package:mobile/features/admin/domain/entities/location_traffic_entity.dart';

class LocationTrafficModel extends LocationTrafficEntity {
  const LocationTrafficModel({
    required super.location,
    required super.value,
    super.percentage,
  });

  factory LocationTrafficModel.fromJson(Map<String, dynamic> json) {
    return LocationTrafficModel(
      location: json['location'] ?? '',
      value: json['value'] ?? 0,
      percentage: json['percentage']?.toString(),
    );
  }

  // ✅ Convert to Entity
  LocationTrafficEntity toEntity() {
    return this;
  }

  Map<String, dynamic> toJson() {
    return {'location': location, 'value': value, 'percentage': percentage};
  }
}
