import 'package:equatable/equatable.dart';
import 'package:flutter/animation.dart';

enum OrderDetailStatus { pending, processing, shipped, delivered, cancelled }

extension OrderDetailStatusExtension on OrderDetailStatus {
  String get displayName {
    switch (this) {
      case OrderDetailStatus.pending:
        return 'Pending';
      case OrderDetailStatus.processing:
        return 'Processing';
      case OrderDetailStatus.shipped:
        return 'Shipped';
      case OrderDetailStatus.delivered:
        return 'Delivered';
      case OrderDetailStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case OrderDetailStatus.pending:
        return const Color(0xFFFFF3E0);
      case OrderDetailStatus.processing:
        return const Color(0xFFE3F2FD);
      case OrderDetailStatus.shipped:
        return const Color(0xFFE8F5E9);
      case OrderDetailStatus.delivered:
        return const Color(0xFFE8F5E9);
      case OrderDetailStatus.cancelled:
        return const Color(0xFFFFEBEE);
    }
  }

  Color get textColor {
    switch (this) {
      case OrderDetailStatus.pending:
        return const Color(0xFFFF9800);
      case OrderDetailStatus.processing:
        return const Color(0xFF2196F3);
      case OrderDetailStatus.shipped:
        return const Color(0xFF4CAF50);
      case OrderDetailStatus.delivered:
        return const Color(0xFF4CAF50);
      case OrderDetailStatus.cancelled:
        return const Color(0xFFF44336);
    }
  }
}

enum PaymentDetailStatus { paid, pending, failed }

extension PaymentDetailStatusExtension on PaymentDetailStatus {
  String get displayName {
    switch (this) {
      case PaymentDetailStatus.paid:
        return 'Paid';
      case PaymentDetailStatus.pending:
        return 'Pending';
      case PaymentDetailStatus.failed:
        return 'Failed';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case PaymentDetailStatus.paid:
        return const Color(0xFFE8F5E9);
      case PaymentDetailStatus.pending:
        return const Color(0xFFFFF3E0);
      case PaymentDetailStatus.failed:
        return const Color(0xFFFFEBEE);
    }
  }

  Color get textColor {
    switch (this) {
      case PaymentDetailStatus.paid:
        return const Color(0xFF4CAF50);
      case PaymentDetailStatus.pending:
        return const Color(0xFFFF9800);
      case PaymentDetailStatus.failed:
        return const Color(0xFFF44336);
    }
  }
}

class OrderDetailItem extends Equatable {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final double totalPrice;
  final String imageUrl;

  const OrderDetailItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [id, name, quantity, price, totalPrice, imageUrl];
}

class OrderDetails extends Equatable {
  final String id;
  final String orderNumber;
  final DateTime createdAt;
  final OrderDetailStatus status;
  final PaymentDetailStatus paymentStatus;
  final String paymentMethod;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double total;
  final String recipientName;
  final String recipientPhone;
  final String deliveryAddress;
  final String? notes;
  final bool canTrack;
  final bool canReorder;
  final List<OrderDetailItem> items;

  const OrderDetails({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    required this.total,
    required this.recipientName,
    required this.recipientPhone,
    required this.deliveryAddress,
    this.notes,
    required this.canTrack,
    required this.canReorder,
    required this.items,
  });

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} • ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    createdAt,
    status,
    paymentStatus,
    paymentMethod,
    subtotal,
    shippingFee,
    discount,
    total,
    recipientName,
    recipientPhone,
    deliveryAddress,
    notes,
    canTrack,
    canReorder,
    items,
  ];
}
