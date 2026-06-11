import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String id;
  final String label;
  final String fullAddress;
  final String phoneNumber;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.phoneNumber,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      label: json['label'] as String,
      fullAddress: json['fullAddress'] as String,
      phoneNumber: json['phoneNumber'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'fullAddress': fullAddress,
      'phoneNumber': phoneNumber,
      'isDefault': isDefault,
    };
  }

  @override
  List<Object?> get props => [id, label, fullAddress, phoneNumber, isDefault];
}
