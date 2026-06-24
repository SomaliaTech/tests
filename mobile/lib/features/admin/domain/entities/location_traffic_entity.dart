import 'package:equatable/equatable.dart';

class LocationTrafficEntity extends Equatable {
  final String location;
  final int value;
  final String? percentage;

  const LocationTrafficEntity({
    required this.location,
    required this.value,
    this.percentage,
  });

  @override
  List<Object?> get props => [location, value, percentage];
}
