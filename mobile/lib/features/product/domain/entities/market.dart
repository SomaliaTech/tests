// lib/features/profile/domain/entities/market.dart
import 'package:equatable/equatable.dart';

class Market extends Equatable {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? slug;

  const Market({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.slug,
  });

  factory Market.fromJson(Map<String, dynamic> json) {
    return Market(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      slug: json['slug'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'slug': slug,
    };
  }

  @override
  List<Object?> get props => [id, name, address, phone, email, slug];
}
