import 'package:equatable/equatable.dart';

class DeviceTrafficEntity extends Equatable {
  final String device;
  final int value;
  final String? color;

  const DeviceTrafficEntity({
    required this.device,
    required this.value,
    this.color,
  });

  @override
  List<Object?> get props => [device, value, color];
}
