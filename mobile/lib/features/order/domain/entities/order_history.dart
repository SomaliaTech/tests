import 'package:equatable/equatable.dart';

enum OrderHistoryStatus { pending, processing, shipped, delivered, cancelled }

extension OrderHistoryStatusExtension on OrderHistoryStatus {
  String get displayName {
    switch (this) {
      case OrderHistoryStatus.pending:
        return 'Pending';
      case OrderHistoryStatus.processing:
        return 'Processing';
      case OrderHistoryStatus.shipped:
        return 'Shipped';
      case OrderHistoryStatus.delivered:
        return 'Delivered';
      case OrderHistoryStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case OrderHistoryStatus.pending:
        return Color(0xFFFFA726);
      case OrderHistoryStatus.processing:
        return Color(0xFF42A5F5);
      case OrderHistoryStatus.shipped:
        return Color(0xFF2ED573);
      case OrderHistoryStatus.delivered:
        return Color(0xFF66BB6A);
      case OrderHistoryStatus.cancelled:
        return Color(0xFFEF5350);
    }
  }
}

class OrderHistoryItem extends Equatable {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final double totalPrice;
  final String imageUrl;

  const OrderHistoryItem({
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

class OrderHistory extends Equatable {
  final String id;
  final String orderNumber;
  final DateTime createdAt;
  final OrderHistoryStatus status;
  final double total;
  final String? trackingNumber;
  final List<OrderHistoryItem> items;

  const OrderHistory({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    required this.status,
    required this.total,
    this.trackingNumber,
    required this.items,
  });

  String get formattedDateLong {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} • ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    createdAt,
    status,
    total,
    trackingNumber,
    items,
  ];
}
