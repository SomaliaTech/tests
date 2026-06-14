import 'package:mobile/features/order/domain/entities/order_history.dart';

class OrderHistoryModel {
  const OrderHistoryModel._();

  static OrderHistory fromJson(Map<String, dynamic> json) {
    final items =
        (json['items'] as List?)?.map((item) {
          // 🚀 Extract image URL from the nested variant -> product -> images structure
          String imageUrl = '';
          try {
            final images = item['variant']?['product']?['images'] as List?;
            if (images != null && images.isNotEmpty) {
              imageUrl = images[0]['url'] as String? ?? '';
            }
          } catch (_) {}

          return OrderHistoryItem(
            id: item['id'] as String? ?? '',
            name: item['productName'] as String? ?? 'Product',
            quantity: item['quantity'] as int? ?? 1,
            // Use tryParse to prevent crashes if backend sends a number instead of string
            price: double.tryParse(item['unitPrice']?.toString() ?? '0') ?? 0.0,
            totalPrice:
                double.tryParse(item['totalPrice']?.toString() ?? '0') ?? 0.0,
            imageUrl: imageUrl,
          );
        }).toList() ??
        [];

    return OrderHistory(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: _parseStatus(json['status'] as String),
      total: double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
      trackingNumber: json['trackingNumber'] as String?,
      items: items,
    );
  }

  static OrderHistoryStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return OrderHistoryStatus.pending;
      case 'PROCESSING':
      case 'CONFIRMED': // 🚨 Added CONFIRMED since your backend sets this after payment
        return OrderHistoryStatus.processing;
      case 'SHIPPED':
        return OrderHistoryStatus.shipped;
      case 'DELIVERED':
        return OrderHistoryStatus.delivered;
      case 'CANCELLED':
        return OrderHistoryStatus.cancelled;
      default:
        return OrderHistoryStatus.pending;
    }
  }
}
