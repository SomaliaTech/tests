// lib/core/common/widgets/shared/payment_method.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class PaymentMethod {
  final String id;
  final String name;
  final String prefix;
  final String description;
  final Color color;
  final IconData icon;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.prefix,
    required this.description,
    required this.color,
    required this.icon,
  });

  static List<PaymentMethod> get methods => [
    const PaymentMethod(
      id: 'evc_plus',
      name: 'EVC Plus (Hormuud)',
      prefix: '61',
      description: 'Bixinta EVC Plus',
      color: Color(0xFF2ED573),
      icon: Iconsax.wallet,
    ),
    const PaymentMethod(
      id: 'zaad',
      name: 'Zaad (Telesom)',
      prefix: '63',
      description: 'Bixinta Zaad',
      color: Color(0xFF8B5CF6),
      icon: Iconsax.money,
    ),
    const PaymentMethod(
      id: 'somnet',
      name: 'Somnet',
      prefix: '68',
      description: 'Bixinta Somnet',
      color: Color(0xFF3B82F6),
      icon: Iconsax.wifi,
    ),
    const PaymentMethod(
      id: 'golis',
      name: 'Golis',
      prefix: '90',
      description: 'Bixinta Golis',
      color: Color(0xFFF59E0B),
      icon: Iconsax.card,
    ),
  ];

  static PaymentMethod? getById(String id) {
    try {
      return methods.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
