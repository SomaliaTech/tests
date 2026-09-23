// lib/features/order/data/models/order_details_model.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../domain/entities/order_details.dart';

class OrderDetailsModel {
  const OrderDetailsModel._();

  static OrderDetails fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('📦 [OrderDetailsModel] Raw response:');
      debugPrint(const JsonEncoder.withIndent('  ').convert(json));
      debugPrint('═══════════════════════════════════════');
    }

    final rawItems = (json['items'] as List<dynamic>?) ?? [];
    final items = rawItems
        .map((e) => _parseOrderItem(e as Map<String, dynamic>))
        .toList();

    double itemsSubtotal = 0.0;
    for (final item in items) {
      final lineTotal = item.totalPrice > 0
          ? item.totalPrice
          : item.price * item.quantity;
      itemsSubtotal += lineTotal;
    }

    final apiTotal = _parseDouble(json['totalAmount'] ?? json['total'] ?? 0);
    final discount = _parseDouble(
      json['promoCodeDiscount'] ?? json['discount'] ?? 0,
    );

    final rawShipping = apiTotal + discount - itemsSubtotal;
    final shippingFee = rawShipping > 0 ? rawShipping : 0.0;

    if (kDebugMode) {
      debugPrint(
        '📊 OrderDetails: Items=$itemsSubtotal, '
        'Total=$apiTotal, Discount=$discount, Shipping=$shippingFee',
      );
    }

    return OrderDetails(
      id: json['id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: _parseStatus(json['status'] as String? ?? 'PENDING'),
      paymentStatus: _parsePaymentStatus(
        json['paymentStatus'] as String? ?? 'PENDING',
      ),
      paymentMethod: json['paymentMethod'] as String? ?? 'Cash on Delivery',
      subtotal: itemsSubtotal,
      shippingFee: shippingFee,
      discount: discount,
      total: apiTotal,
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

  // ─────────────────────────────────────────────────
  // ITEM PARSING
  // ─────────────────────────────────────────────────
  static OrderDetailItem _parseOrderItem(Map<String, dynamic> item) {
    final imageUrl = _extractImageUrl(item);

    if (kDebugMode) {
      debugPrint('🖼️ Item "${item['productName']}" → imageUrl: "$imageUrl"');
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

  /// Try every possible path for the image URL.
  static String _extractImageUrl(Map<String, dynamic> item) {
    try {
      // 1. Direct product.images (no variant)
      final product = item['product'];
      if (product is Map) {
        final url = _firstImageUrl(product['images']);
        if (url.isNotEmpty) return url;

        // 1b) product.imageUrl / product.image
        final pUrl =
            product['imageUrl']?.toString() ??
            product['image']?.toString() ??
            '';
        if (pUrl.isNotEmpty) return pUrl;
      }

      // 2. variant.product.images
      final variant = item['variant'];
      if (variant is Map) {
        final vProduct = variant['product'];
        if (vProduct is Map) {
          final url = _firstImageUrl(vProduct['images']);
          if (url.isNotEmpty) return url;
        }
      }

      // 3. Flat fallbacks on the item itself
      final flat =
          item['productImage']?.toString() ??
          item['imageUrl']?.toString() ??
          item['image']?.toString() ??
          '';
      if (flat.isNotEmpty) return flat;

      // 4. item.images directly
      final url = _firstImageUrl(item['images']);
      if (url.isNotEmpty) return url;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OrderDetailsModel] image extract failed: $e');
      }
    }
    return '';
  }

  static String _firstImageUrl(dynamic images) {
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is Map) {
        return first['url']?.toString() ??
            first['imageUrl']?.toString() ??
            first['secureUrl']?.toString() ??
            first['publicUrl']?.toString() ??
            '';
      }
      if (first is String) return first;
    }
    if (images is Map) {
      return images['url']?.toString() ?? images['imageUrl']?.toString() ?? '';
    }
    if (images is String) return images;
    return '';
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

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
