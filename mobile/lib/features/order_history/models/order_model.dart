import 'package:flutter/material.dart';

enum OrderStatus { delivered, processing, shipped, cancelled, active }

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.active:
        return 'Active';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case OrderStatus.delivered:
        return const Color(0xFFE8F5E9);
      case OrderStatus.processing:
        return const Color(0xFFFFF3E0);
      case OrderStatus.shipped:
        return const Color(0xFFE3F2FD);
      case OrderStatus.cancelled:
        return const Color(0xFFFFEBEE);
      case OrderStatus.active:
        return const Color(0xFFE8F5E9);
    }
  }

  Color get textColor {
    switch (this) {
      case OrderStatus.delivered:
        return const Color(0xFF2ED573);
      case OrderStatus.processing:
        return const Color(0xFFFFA502);
      case OrderStatus.shipped:
        return const Color(0xFF3742FA);
      case OrderStatus.cancelled:
        return const Color(0xFFFF4757);
      case OrderStatus.active:
        return const Color(0xFF2ED573);
    }
  }

  Color get borderColor {
    switch (this) {
      case OrderStatus.delivered:
        return const Color(0xFF2ED573);
      case OrderStatus.processing:
        return const Color(0xFFFFA502);
      case OrderStatus.shipped:
        return const Color(0xFF3742FA);
      case OrderStatus.cancelled:
        return const Color(0xFFFF4757);
      case OrderStatus.active:
        return const Color(0xFF2ED573);
    }
  }
}

class OrderItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String imageUrl;

  const OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.imageUrl,
  });

  double get totalPrice => price * quantity;
}

class Order {
  final String id;
  final DateTime date;
  final List<OrderItem> items;
  final double total;
  final OrderStatus status;
  final String? trackingNumber;

  const Order({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    required this.status,
    this.trackingNumber,
  });

  String get formattedDate {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  String get formattedDateLong {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// Mock Data
final List<Order> productOrders = [
  Order(
    id: 'ORD-2024-001',
    date: DateTime(2026, 6, 1),
    items: [
      const OrderItem(
        id: '1',
        name: 'MIISAANKA BODY+ FAT',
        quantity: 1,
        price: 15.00,
        imageUrl:
            'https://images.unsplash.com/photo-1576243345690-8e4b879f2c6e?w=200&h=200&fit=crop',
      ),
      const OrderItem(
        id: '2',
        name: 'ABDOMINAL WHEEL ROLLER',
        quantity: 1,
        price: 16.00,
        imageUrl:
            'https://images.unsplash.com/photo-1598289431512-b97b0917affc?w=200&h=200&fit=crop',
      ),
    ],
    total: 31.00,
    status: OrderStatus.delivered,
    trackingNumber: 'TRK987654321',
  ),
  Order(
    id: 'ORD-2024-002',
    date: DateTime(2026, 5, 28),
    items: [
      const OrderItem(
        id: '3',
        name: 'Smart Watch Pro',
        quantity: 1,
        price: 89.00,
        imageUrl:
            'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=200&h=200&fit=crop',
      ),
    ],
    total: 89.00,
    status: OrderStatus.shipped,
    trackingNumber: 'TRK123456789',
  ),
  Order(
    id: 'ORD-2024-003',
    date: DateTime(2026, 5, 25),
    items: [
      const OrderItem(
        id: '4',
        name: 'Resistance Bands Set',
        quantity: 2,
        price: 12.00,
        imageUrl:
            'https://images.unsplash.com/photo-1598289431512-b97b0917affc?w=200&h=200&fit=crop',
      ),
    ],
    total: 24.00,
    status: OrderStatus.processing,
  ),
];

final List<Order> internetOrders = [
  Order(
    id: 'NET-2024-045',
    date: DateTime(2026, 6, 2),
    items: [
      const OrderItem(
        id: 'net1',
        name: 'Monthly Fiber Internet Plan',
        quantity: 1,
        price: 45.00,
        imageUrl:
            'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=200&h=200&fit=crop',
      ),
    ],
    total: 45.00,
    status: OrderStatus.active,
  ),
  Order(
    id: 'NET-2024-032',
    date: DateTime(2026, 5, 1),
    items: [
      const OrderItem(
        id: 'net2',
        name: 'Basic WiFi Package',
        quantity: 1,
        price: 25.00,
        imageUrl:
            'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?w=200&h=200&fit=crop',
      ),
    ],
    total: 25.00,
    status: OrderStatus.cancelled,
  ),
];
