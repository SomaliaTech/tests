import '../../domain/entities/admin_order_entity.dart';

class AdminOrderModel extends AdminOrderEntity {
  const AdminOrderModel({
    required super.id,
    required super.orderNumber,
    required super.customerName,
    super.customerEmail,
    super.customerPhone,
    super.shippingAddress,
    required super.totalAmount,
    required super.status,
    required super.paymentStatus,
    super.paymentMethod,
    super.notes,
    required super.itemsCount,
    required super.itemNames,
    required super.createdAt,
  });

  factory AdminOrderModel.fromJson(Map<String, dynamic> json) {
    // Extract items data from the nested backend response
    final items = json['items'] as List<dynamic>? ?? [];
    final itemsCount = items.length;
    final itemNames = items
        .map((item) {
          return item['variant']?['product']?['name'] ?? 'Unknown Product';
        })
        .join(', ');

    return AdminOrderModel(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      customerName: json['customerName'] ?? 'Unknown',
      customerEmail: json['customerEmail'],
      customerPhone: json['customerPhone'],
      shippingAddress: json['shippingAddress'],
      totalAmount: json['totalAmount']?.toString() ?? '0',
      status: json['status'] ?? 'PENDING',
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
      paymentMethod: json['paymentMethod'],
      notes: json['notes'],
      itemsCount: itemsCount,
      itemNames: itemNames,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
