import '../../domain/entities/admin_revenue_entity.dart';

class AdminRevenueModel extends AdminRevenueEntity {
  const AdminRevenueModel({
    required super.id,
    required super.orderNumber,
    required super.customerName,
    super.customerEmail,
    super.customerPhone,
    super.shippingAddress,
    required super.subtotal,
    required super.totalAmount,
    super.paymentMethod,
    required super.paymentStatus,
    required super.status,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
    required super.items,
  });

  factory AdminRevenueModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((item) => AdminRevenueItemModel.fromJson(item))
        .toList();

    return AdminRevenueModel(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      customerName: json['customerName'] ?? 'Unknown',
      customerEmail: json['customerEmail'],
      customerPhone: json['customerPhone'],
      shippingAddress: json['shippingAddress'],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
      status: json['status'] ?? 'PENDING',
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      items: items,
    );
  }
}

class AdminRevenueItemModel extends AdminRevenueItemEntity {
  const AdminRevenueItemModel({
    required super.id,
    required super.productName,
    super.variantSku,
    super.colorName,
    super.sizeName,
    required super.unitPrice,
    required super.quantity,
    required super.totalPrice,
    super.productImage,
    super.category,
  });

  factory AdminRevenueItemModel.fromJson(Map<String, dynamic> json) {
    return AdminRevenueItemModel(
      id: json['id'] ?? '',
      productName: json['productName'] ?? 'Unknown Product',
      variantSku: json['variantSku'],
      colorName: json['colorName'],
      sizeName: json['sizeName'],
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      productImage: json['productImage'],
      category: json['category'],
    );
  }
}

class AdminRevenueSummaryModel extends AdminRevenueSummaryEntity {
  const AdminRevenueSummaryModel({
    required super.totalRevenue,
    required super.totalOrders,
    required super.averageOrderValue,
    required super.growth,
    required super.paymentBreakdown,
  });

  factory AdminRevenueSummaryModel.fromJson(Map<String, dynamic> json) {
    final breakdown = (json['paymentBreakdown'] as List<dynamic>? ?? [])
        .map((item) => PaymentBreakdownModel.fromJson(item))
        .toList();

    return AdminRevenueSummaryModel(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      averageOrderValue: (json['averageOrderValue'] ?? 0).toDouble(),
      growth: (json['growth'] ?? 0).toDouble(),
      paymentBreakdown: breakdown,
    );
  }
}

class PaymentBreakdownModel extends PaymentBreakdownEntity {
  const PaymentBreakdownModel({
    required super.method,
    required super.total,
    required super.count,
  });

  factory PaymentBreakdownModel.fromJson(Map<String, dynamic> json) {
    return PaymentBreakdownModel(
      method: json['method'] ?? 'unknown',
      total: (json['total'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class AdminRevenueListModel extends AdminRevenueListEntity {
  const AdminRevenueListModel({
    required super.id,
    required super.orderNumber,
    required super.customerName,
    super.customerEmail,
    required super.totalAmount,
    super.paymentMethod,
    required super.paymentStatus,
    required super.status,
    required super.itemsCount,
    required super.createdAt,
  });

  factory AdminRevenueListModel.fromJson(Map<String, dynamic> json) {
    return AdminRevenueListModel(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      customerName: json['customerName'] ?? 'Unknown',
      customerEmail: json['customerEmail'],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
      status: json['status'] ?? 'PENDING',
      itemsCount: json['itemsCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
