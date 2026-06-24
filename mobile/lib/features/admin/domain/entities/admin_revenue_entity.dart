import 'package:equatable/equatable.dart';

class AdminRevenueEntity extends Equatable {
  final String id;
  final String orderNumber;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? shippingAddress;
  final double subtotal;
  final double totalAmount;
  final String? paymentMethod;
  final String paymentStatus;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AdminRevenueItemEntity> items;

  const AdminRevenueEntity({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.shippingAddress,
    required this.subtotal,
    required this.totalAmount,
    this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    customerName,
    customerEmail,
    customerPhone,
    shippingAddress,
    subtotal,
    totalAmount,
    paymentMethod,
    paymentStatus,
    status,
    notes,
    createdAt,
    updatedAt,
    items,
  ];
}

class AdminRevenueItemEntity extends Equatable {
  final String id;
  final String productName;
  final String? variantSku;
  final String? colorName;
  final String? sizeName;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final String? productImage;
  final String? category;

  const AdminRevenueItemEntity({
    required this.id,
    required this.productName,
    this.variantSku,
    this.colorName,
    this.sizeName,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    this.productImage,
    this.category,
  });

  @override
  List<Object?> get props => [
    id,
    productName,
    variantSku,
    colorName,
    sizeName,
    unitPrice,
    quantity,
    totalPrice,
    productImage,
    category,
  ];
}

class AdminRevenueSummaryEntity extends Equatable {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final double growth;
  final List<PaymentBreakdownEntity> paymentBreakdown;

  const AdminRevenueSummaryEntity({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.growth,
    required this.paymentBreakdown,
  });

  @override
  List<Object?> get props => [
    totalRevenue,
    totalOrders,
    averageOrderValue,
    growth,
    paymentBreakdown,
  ];
}

class PaymentBreakdownEntity extends Equatable {
  final String method;
  final double total;
  final int count;

  const PaymentBreakdownEntity({
    required this.method,
    required this.total,
    required this.count,
  });

  @override
  List<Object?> get props => [method, total, count];
}

class AdminRevenueListEntity extends Equatable {
  final String id;
  final String orderNumber;
  final String customerName;
  final String? customerEmail;
  final double totalAmount;
  final String? paymentMethod;
  final String paymentStatus;
  final String status;
  final int itemsCount;
  final DateTime createdAt;

  const AdminRevenueListEntity({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    this.customerEmail,
    required this.totalAmount,
    this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.itemsCount,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    customerName,
    customerEmail,
    totalAmount,
    paymentMethod,
    paymentStatus,
    status,
    itemsCount,
    createdAt,
  ];
}
