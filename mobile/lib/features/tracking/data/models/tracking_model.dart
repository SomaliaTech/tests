import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

enum TrackingStatus { processing, shipped, outForDelivery, delivered }

extension TrackingStatusExtension on TrackingStatus {
  String get displayName {
    switch (this) {
      case TrackingStatus.processing:
        return 'Processing';
      case TrackingStatus.shipped:
        return 'Shipped';
      case TrackingStatus.outForDelivery:
        return 'Out for Delivery';
      case TrackingStatus.delivered:
        return 'Delivered';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case TrackingStatus.processing:
        return const Color(0xFFFFF3E0);
      case TrackingStatus.shipped:
        return const Color(0xFFE3F2FD);
      case TrackingStatus.outForDelivery:
        return const Color(0xFFE8F5E9);
      case TrackingStatus.delivered:
        return const Color(0xFFE8F5E9);
    }
  }

  Color get textColor {
    switch (this) {
      case TrackingStatus.processing:
        return const Color(0xFFFFA502);
      case TrackingStatus.shipped:
        return const Color(0xFF3742FA);
      case TrackingStatus.outForDelivery:
        return const Color(0xFF2ED573);
      case TrackingStatus.delivered:
        return const Color(0xFF2ED573);
    }
  }

  Color get borderColor {
    switch (this) {
      case TrackingStatus.processing:
        return const Color(0xFFFFA502);
      case TrackingStatus.shipped:
        return const Color(0xFF3742FA);
      case TrackingStatus.outForDelivery:
        return const Color(0xFF2ED573);
      case TrackingStatus.delivered:
        return const Color(0xFF2ED573);
    }
  }
}

class TrackingStep extends Equatable {
  final String id;
  final TrackingStatus status;
  final String title;
  final DateTime date;
  final String location;
  final String? description;

  const TrackingStep({
    required this.id,
    required this.status,
    required this.title,
    required this.date,
    required this.location,
    this.description,
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

  String get formattedTime {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  List<Object?> get props => [id, status, title, date, location, description];
}

class OrderDetails extends Equatable {
  final String id;
  final TrackingStatus status;
  final double total;
  final DateTime date;
  final DateTime estimatedDelivery;
  final String courier;
  final String trackingNumber;
  final String deliveryAddress;
  final String recipientName;
  final String recipientPhone;
  final List<TrackingStep> steps;

  const OrderDetails({
    required this.id,
    required this.status,
    required this.total,
    required this.date,
    required this.estimatedDelivery,
    required this.courier,
    required this.trackingNumber,
    required this.deliveryAddress,
    required this.recipientName,
    required this.recipientPhone,
    required this.steps,
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

  String get formattedEstimatedDelivery {
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
    return '${months[estimatedDelivery.month - 1]} ${estimatedDelivery.day}, ${estimatedDelivery.year}';
  }

  @override
  List<Object?> get props => [
    id,
    status,
    total,
    date,
    estimatedDelivery,
    steps,
  ];
}

// Mock Data
final Map<String, OrderDetails> mockOrders = {
  'ORD-2024-001': OrderDetails(
    id: 'ORD-2024-001',
    status: TrackingStatus.outForDelivery,
    total: 31.00,
    date: DateTime(2026, 6, 1),
    estimatedDelivery: DateTime(2026, 6, 3),
    courier: 'SOOMAR Express',
    trackingNumber: 'TRK987654321',
    deliveryAddress: 'Hodan District, KM4 Road, Mogadishu, Somalia',
    recipientName: 'Eng Soke',
    recipientPhone: '+252 61 673 9858',
    steps: [
      TrackingStep(
        id: '1',
        status: TrackingStatus.outForDelivery,
        title: 'Out for Delivery',
        date: DateTime(2026, 6, 3, 8, 15),
        location: 'Mogadishu Distribution Center',
        description: 'Package is with the courier and out for delivery today.',
      ),
      TrackingStep(
        id: '2',
        status: TrackingStatus.shipped,
        title: 'Shipped',
        date: DateTime(2026, 6, 2, 14, 0),
        location: 'Hargeisa Warehouse',
        description: 'Package has left the warehouse and is in transit.',
      ),
      TrackingStep(
        id: '3',
        status: TrackingStatus.processing,
        title: 'Order Confirmed & Packed',
        date: DateTime(2026, 6, 1, 9, 30),
        location: 'Online',
        description: 'Payment confirmed. Items are being prepared.',
      ),
      TrackingStep(
        id: '4',
        status: TrackingStatus.processing,
        title: 'Order Placed',
        date: DateTime(2026, 6, 1, 9, 0),
        location: 'Online',
        description: 'Your order has been successfully placed.',
      ),
    ],
  ),
};
