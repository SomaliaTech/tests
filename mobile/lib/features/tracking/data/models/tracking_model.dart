import '../../domain/entities/tracking.dart';

class TrackingModel {
  const TrackingModel._();

  static TrackingInfo fromJson(Map<String, dynamic> json) {
    final steps =
        (json['trackingSteps'] as List?)
            ?.map(
              (step) => TrackingStep(
                id: step['id'] as String,
                title: step['title'] as String,
                location: step['location'] as String,
                timestamp: DateTime.parse(step['timestamp'] as String),
                description: step['description'] as String?,
              ),
            )
            .toList() ??
        [];

    return TrackingInfo(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: _parseStatus(json['status'] as String),
      estimatedDelivery: json['estimatedDelivery'] != null
          ? DateTime.parse(json['estimatedDelivery'] as String)
          : null,
      total: double.parse(json['totalAmount'] as String),
      recipientName: json['customerName'] as String,
      recipientPhone: json['customerPhone'] as String? ?? '',
      deliveryAddress: json['shippingAddress'] as String,
      trackingNumber: json['trackingNumber'] as String? ?? 'N/A',
      carrier: json['carrier'] as String? ?? 'Standard Shipping',
      steps: steps,
    );
  }

  static TrackingStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return TrackingStatus.pending;
      case 'PROCESSING':
        return TrackingStatus.processing;
      case 'SHIPPED':
        return TrackingStatus.shipped;
      case 'OUT_FOR_DELIVERY':
      case 'OUT FOR DELIVERY':
        return TrackingStatus.outForDelivery;
      case 'DELIVERED':
        return TrackingStatus.delivered;
      case 'CANCELLED':
        return TrackingStatus.cancelled;
      default:
        return TrackingStatus.pending;
    }
  }
}
