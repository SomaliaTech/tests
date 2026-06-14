import '../../domain/entities/order_history.dart';

class OrderHistoryModel {
  const OrderHistoryModel._();

  static OrderHistory fromJson(Map<String, dynamic> json) {
    // Extract image from variant -> product -> images
    final items =
        (json['items'] as List?)?.map((item) {
          // Get the first image from product images
          String imageUrl = '';
          final variant = item['variant'] as Map<String, dynamic>?;
          if (variant != null) {
            final product = variant['product'] as Map<String, dynamic>?;
            if (product != null) {
              final images = product['images'] as List?;
              if (images != null && images.isNotEmpty) {
                final firstImage = images.first as Map<String, dynamic>;
                imageUrl = firstImage['url'] as String? ?? '';
              }
            }
          }

          return OrderHistoryItem(
            id: item['id'] as String,
            name: item['productName'] as String,
            quantity: item['quantity'] as int,
            price: double.parse(item['unitPrice'] as String),
            totalPrice: double.parse(item['totalPrice'] as String),
            imageUrl: imageUrl,
          );
        }).toList() ??
        [];

    return OrderHistory(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: _parseStatus(json['status'] as String),
      total: double.parse(json['totalAmount'] as String),
      trackingNumber: json['trackingNumber'] as String?,
      items: items,
    );
  }

  static OrderHistoryStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return OrderHistoryStatus.pending;
      case 'PROCESSING':
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
