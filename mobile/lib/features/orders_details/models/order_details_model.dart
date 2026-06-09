import 'package:flutter/material.dart';

enum OrderStatus { delivered, processing, shipped, cancelled }

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
    }
  }
}

enum PaymentStatus { paid, pending, failed }

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.failed:
        return 'Failed';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case PaymentStatus.paid:
        return const Color(0xFFE8F5E9);
      case PaymentStatus.pending:
        return const Color(0xFFFFF3E0);
      case PaymentStatus.failed:
        return const Color(0xFFFFEBEE);
    }
  }

  Color get textColor {
    switch (this) {
      case PaymentStatus.paid:
        return const Color(0xFF2ED573);
      case PaymentStatus.pending:
        return const Color(0xFFFFA502);
      case PaymentStatus.failed:
        return const Color(0xFFFF4757);
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

class OrderDetails {
  final String id;
  final DateTime date;
  final OrderStatus status;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double total;
  final String deliveryAddress;
  final String recipientName;
  final String recipientPhone;
  final String paymentMethod;
  final PaymentStatus paymentStatus;
  final String? notes;

  const OrderDetails({
    required this.id,
    required this.date,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    required this.total,
    required this.deliveryAddress,
    required this.recipientName,
    required this.recipientPhone,
    required this.paymentMethod,
    required this.paymentStatus,
    this.notes,
  });

  String get formattedDate {
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

  bool get canReorder => status == OrderStatus.delivered;
  bool get canTrack =>
      status == OrderStatus.shipped || status == OrderStatus.processing;
}

// Mock Data
final Map<String, OrderDetails> mockOrderDetails = {
  'ORD-2024-001': OrderDetails(
    id: 'ORD-2024-001',
    date: DateTime(2026, 6, 1),
    status: OrderStatus.delivered,
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
    subtotal: 31.00,
    shippingFee: 5.00,
    discount: 0,
    total: 36.00,
    deliveryAddress:
        'Hodan District, KM4 Road, Near Somali Museum\nMogadishu, Somalia',
    recipientName: 'Eng Soke',
    recipientPhone: '+252 61 673 9858',
    paymentMethod: 'EVC Plus',
    paymentStatus: PaymentStatus.paid,
    notes: 'Please call upon arrival',
  ),
  'ORD-2024-002': OrderDetails(
    id: 'ORD-2024-002',
    date: DateTime(2026, 5, 28),
    status: OrderStatus.shipped,
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
    subtotal: 89.00,
    shippingFee: 0,
    discount: 10.00,
    total: 79.00,
    deliveryAddress:
        'Hodan District, KM4 Road, Near Somali Museum\nMogadishu, Somalia',
    recipientName: 'Eng Soke',
    recipientPhone: '+252 61 673 9858',
    paymentMethod: 'Cash on Delivery',
    paymentStatus: PaymentStatus.pending,
  ),
};
