import 'package:mobile/features/order/domain/entities/order_history.dart';

class OrderHistoryModel {
  const OrderHistoryModel._();

  static OrderHistory fromJson(Map<String, dynamic> json) {
    final items =
        (json['items'] as List?)?.map((item) {
          // ✅ FIXED: Better image URL extraction with fallback
          String imageUrl = '';
          try {
            // Try variant -> product -> images
            final images = item['variant']?['product']?['images'] as List?;
            if (images != null && images.isNotEmpty) {
              final firstImage = images[0];
              if (firstImage is Map) {
                imageUrl = firstImage['url']?.toString() ?? '';
              } else if (firstImage is String) {
                imageUrl = firstImage;
              }
            }

            // ✅ Fallback: try direct product images
            if (imageUrl.isEmpty) {
              final productImages = item['product']?['images'] as List?;
              if (productImages != null && productImages.isNotEmpty) {
                final firstImage = productImages[0];
                if (firstImage is Map) {
                  imageUrl = firstImage['url']?.toString() ?? '';
                } else if (firstImage is String) {
                  imageUrl = firstImage;
                }
              }
            }

            // ✅ Fallback: use placeholder if still empty
            if (imageUrl.isEmpty) {
              imageUrl = ''; // Let the widget show placeholder
            }
          } catch (_) {
            imageUrl = '';
          }

          return OrderHistoryItem(
            id: item['id'] as String? ?? '',
            name: item['productName'] as String? ?? 'Product',
            quantity: item['quantity'] as int? ?? 1,
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
      case 'CONFIRMED':
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
