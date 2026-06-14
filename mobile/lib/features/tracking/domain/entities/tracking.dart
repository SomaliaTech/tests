import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum TrackingStatus {
  pending,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
}

extension TrackingStatusExtension on TrackingStatus {
  String get displayName {
    switch (this) {
      case TrackingStatus.pending:
        return 'Pending';
      case TrackingStatus.processing:
        return 'Processing';
      case TrackingStatus.shipped:
        return 'Shipped';
      case TrackingStatus.outForDelivery:
        return 'Out for Delivery';
      case TrackingStatus.delivered:
        return 'Delivered';
      case TrackingStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case TrackingStatus.pending:
        return const Color(0xFFFFF3E0);
      case TrackingStatus.processing:
        return const Color(0xFFE3F2FD);
      case TrackingStatus.shipped:
        return const Color(0xFFE8F5E9);
      case TrackingStatus.outForDelivery:
        return const Color(0xFFE3F2FD);
      case TrackingStatus.delivered:
        return const Color(0xFFE8F5E9);
      case TrackingStatus.cancelled:
        return const Color(0xFFFFEBEE);
    }
  }

  Color get textColor {
    switch (this) {
      case TrackingStatus.pending:
        return const Color(0xFFFF9800);
      case TrackingStatus.processing:
        return const Color(0xFF2196F3);
      case TrackingStatus.shipped:
        return const Color(0xFF4CAF50);
      case TrackingStatus.outForDelivery:
        return const Color(0xFF2196F3);
      case TrackingStatus.delivered:
        return const Color(0xFF4CAF50);
      case TrackingStatus.cancelled:
        return const Color(0xFFF44336);
    }
  }

  Color get borderColor {
    switch (this) {
      case TrackingStatus.pending:
        return const Color(0xFFFFE0B2);
      case TrackingStatus.processing:
        return const Color(0xFFBBDEFB);
      case TrackingStatus.shipped:
        return const Color(0xFFC8E6C9);
      case TrackingStatus.outForDelivery:
        return const Color(0xFFBBDEFB);
      case TrackingStatus.delivered:
        return const Color(0xFFC8E6C9);
      case TrackingStatus.cancelled:
        return const Color(0xFFFFCDD2);
    }
  }

  int get stepIndex {
    switch (this) {
      case TrackingStatus.pending:
        return 0;
      case TrackingStatus.processing:
        return 1;
      case TrackingStatus.shipped:
        return 2;
      case TrackingStatus.outForDelivery:
        return 3;
      case TrackingStatus.delivered:
        return 4;
      case TrackingStatus.cancelled:
        return -1;
    }
  }
}

class TrackingStep extends Equatable {
  final String id;
  final String title;
  final String location;
  final DateTime timestamp;
  final String? description;

  const TrackingStep({
    required this.id,
    required this.title,
    required this.location,
    required this.timestamp,
    this.description,
  });

  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  String get formattedTime {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [id, title, location, timestamp, description];
}

class TrackingInfo extends Equatable {
  final String id;
  final String orderNumber;
  final DateTime createdAt;
  final TrackingStatus status;
  final DateTime? estimatedDelivery;
  final double total;
  final String recipientName;
  final String recipientPhone;
  final String deliveryAddress;
  final String trackingNumber;
  final String carrier;
  final List<TrackingStep> steps;

  const TrackingInfo({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    required this.status,
    this.estimatedDelivery,
    required this.total,
    required this.recipientName,
    required this.recipientPhone,
    required this.deliveryAddress,
    required this.trackingNumber,
    required this.carrier,
    required this.steps,
  });

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get formattedEstimatedDelivery {
    if (estimatedDelivery == null) return 'Not available';
    return '${estimatedDelivery!.day}/${estimatedDelivery!.month}/${estimatedDelivery!.year}';
  }

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    createdAt,
    status,
    estimatedDelivery,
    total,
    recipientName,
    recipientPhone,
    deliveryAddress,
    trackingNumber,
    carrier,
    steps,
  ];
}
