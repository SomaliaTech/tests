// lib/features/product/presentation/models/payment_method.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final String prefix; // Only the 2-digit prefix (61, 68, 90, 63)

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.prefix,
  });
  // In payment_method.dart
  static const List<PaymentMethod> methods = [
    PaymentMethod(
      id: 'evc_plus',
      name: 'EVC Plus',
      icon: Iconsax.mobile,
      color: Color(0xFF2ED573),
      description: 'Pay with EVC Plus mobile money',
      prefix: '61', // ✅ Fixed: EVC Plus is 61
    ),
    PaymentMethod(
      id: 'somnet',
      name: 'Somnet',
      icon: Iconsax.wifi,
      color: Color(0xFF3B82F6),
      description: 'Pay with Somnet mobile money',
      prefix: '68',
    ),
    PaymentMethod(
      id: 'golis_telcom',
      name: 'Golis Telcome',
      icon: Iconsax.wallet,
      color: Color(0xFFF59E0B),
      description: 'Pay with Golis Telcome',
      prefix: '90',
    ),
    PaymentMethod(
      id: 'telisom',
      name: 'Telisom',
      icon: Iconsax.money,
      color: Color(0xFF8B5CF6),
      description: 'Pay with Telisom',
      prefix: '63',
    ),
  ];
}
