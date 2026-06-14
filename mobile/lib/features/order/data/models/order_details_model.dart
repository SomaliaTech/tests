import '../../domain/entities/order_details.dart';

class OrderDetailsModel {
  const OrderDetailsModel._();

  static OrderDetails fromJson(Map<String, dynamic> json) {
    final items =
        (json['items'] as List?)?.map((item) {
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

          return OrderDetailItem(
            id: item['id'] as String,
            name: item['productName'] as String,
            quantity: item['quantity'] as int,
            price: double.parse(item['unitPrice'] as String),
            totalPrice: double.parse(item['totalPrice'] as String),
            imageUrl: imageUrl,
          );
        }).toList() ??
        [];

    return OrderDetails(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: _parseStatus(json['status'] as String),
      paymentStatus: _parsePaymentStatus(
        json['paymentStatus'] as String ?? 'pending',
      ),
      paymentMethod: json['paymentMethod'] as String? ?? 'Cash on Delivery',
      subtotal: double.parse(json['totalAmount'] as String),
      shippingFee: 0.0,
      discount: 0.0,
      total: double.parse(json['totalAmount'] as String),
      recipientName: json['customerName'] as String,
      recipientPhone: json['customerPhone'] as String? ?? '',
      deliveryAddress: json['shippingAddress'] as String,
      notes: json['notes'] as String?,
      canTrack: json['status'] == 'SHIPPED',
      canReorder: json['status'] != 'CANCELLED',
      items: items,
    );
  }

  static OrderDetailStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return OrderDetailStatus.pending;
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
