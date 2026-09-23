// lib/features/order/data/models/order_history_model.dart
import 'package:flutter/foundation.dart';
import '../../domain/entities/order_history.dart';

class OrderHistoryModel {
  const OrderHistoryModel._();

  static OrderHistory fromJson(Map<String, dynamic> json) {
    final items =
        (json['items'] as List?)?.map((raw) {
          final item = raw as Map<String, dynamic>;
          final imageUrl = _extractImageUrl(item);

          return OrderHistoryItem(
            id: item['id'] as String? ?? '',
            name: item['productName'] as String? ?? 'Product',
            quantity: (item['quantity'] as num?)?.toInt() ?? 1,
            price: _parseDouble(item['unitPrice']),
            totalPrice: _parseDouble(item['totalPrice']),
            imageUrl: imageUrl,
          );
        }).toList() ??
        [];

    return OrderHistory(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: _parseStatus(json['status'] as String),
      total: _parseDouble(json['totalAmount']),
      trackingNumber: json['trackingNumber'] as String?,
      items: items,
    );
  }

  /// Try every known path to find an image URL.
  static String _extractImageUrl(Map<String, dynamic> item) {
    try {
      // 1. Direct product.images (for items with no variant)
      final product = item['product'];
      if (product is Map) {
        final url = _firstImageUrl(product['images']);
        if (url.isNotEmpty) return url;

        final url2 = _firstImageUrl(product['mediaAssets']);
        if (url2.isNotEmpty) return url2;

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

          final url2 = _firstImageUrl(vProduct['mediaAssets']);
          if (url2.isNotEmpty) return url2;
        }
      }

      // 3. Flat fallbacks
      final flat1 = item['productImage']?.toString() ?? '';
      if (flat1.isNotEmpty) return flat1;

      final flat2 = item['imageUrl']?.toString() ?? '';
      if (flat2.isNotEmpty) return flat2;

      final flat3 = item['image']?.toString() ?? '';
      if (flat3.isNotEmpty) return flat3;

      // 4. images directly on item
      final url = _firstImageUrl(item['images']);
      if (url.isNotEmpty) return url;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [OrderHistoryModel] image extract failed: $e');
      }
    }

    return '';
  }

  static String _firstImageUrl(dynamic images) {
    if (images == null) return '';

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

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
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
