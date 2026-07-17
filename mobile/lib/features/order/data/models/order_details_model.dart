// lib/features/admin/data/models/order_details_model.dart

import '../../domain/entities/order_details.dart';

class OrderDetailsModel {
  const OrderDetailsModel._();

  static OrderDetails fromJson(Map<String, dynamic> json) {
    // Parse items
    final items =
        (json['items'] as List<dynamic>?)
            ?.map((item) => _parseOrderItem(item as Map<String, dynamic>))
            .toList() ??
        [];

    return OrderDetails(
      id: json['id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      status: _parseStatus(json['status'] as String? ?? 'PENDING'),
      paymentStatus: _parsePaymentStatus(
        json['paymentStatus'] as String? ?? 'PENDING',
      ),
      paymentMethod: json['paymentMethod'] as String? ?? 'Cash on Delivery',
      subtotal: _parseDouble(json['subtotal']),
      shippingFee: _parseDouble(json['shippingFee'] ?? json['shipping'] ?? 0),
      discount: _parseDouble(json['discount'] ?? 0),
      total: _parseDouble(json['totalAmount'] ?? json['total'] ?? 0),
      recipientName: json['customerName'] as String? ?? '',
      recipientPhone:
          json['customerPhone'] as String? ??
          json['shippingPhone'] as String? ??
          '',
      deliveryAddress: json['shippingAddress'] as String? ?? '',
      notes: json['notes'] as String?,
      canTrack: json['status'] == 'SHIPPED',
      canReorder: json['status'] != 'CANCELLED',
      items: items,
    );
  }

  /// Parse a single order item
  static OrderDetailItem _parseOrderItem(Map<String, dynamic> item) {
    // Extract image URL from nested structure
    String imageUrl = '';
    final variant = item['variant'] as Map<String, dynamic>?;
    if (variant != null) {
      final product = variant['product'] as Map<String, dynamic>?;
      if (product != null) {
        final images = product['images'] as List<dynamic>?;
        if (images != null && images.isNotEmpty) {
          final firstImage = images.first as Map<String, dynamic>?;
          imageUrl = firstImage?['url'] as String? ?? '';
        }
      }
    }

    // Also check for direct imageUrl (from revenue endpoint)
    if (imageUrl.isEmpty) {
      imageUrl = item['productImage'] as String? ?? '';
    }

    return OrderDetailItem(
      id: item['id'] as String? ?? '',
      name: item['productName'] as String? ?? 'Unknown Product',
      quantity: _parseInt(item['quantity']),
      price: _parseDouble(item['unitPrice'] ?? item['price']),
      totalPrice: _parseDouble(item['totalPrice']),
      imageUrl: imageUrl,
    );
  }

  /// Parse double from dynamic (handles String, int, double, null)
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Parse int from dynamic (handles String, int, double, null)
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static OrderDetailStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return OrderDetailStatus.pending;
      case 'CONFIRMED':
      case 'PROCESSING':
        return OrderDetailStatus.processing;
      case 'SHIPPED':
        return OrderDetailStatus.shipped;
      case 'DELIVERED':
        return OrderDetailStatus.delivered;
      case 'CANCELLED':
        return OrderDetailStatus.cancelled;
      default:
        return OrderDetailStatus.pending;
    }
  }

  static PaymentDetailStatus _parsePaymentStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return PaymentDetailStatus.paid;
      case 'PENDING':
        return PaymentDetailStatus.pending;
      case 'FAILED':
        return PaymentDetailStatus.failed;
      default:
        return PaymentDetailStatus.pending;
    }
  }
}
