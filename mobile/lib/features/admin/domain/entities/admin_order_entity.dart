import 'package:equatable/equatable.dart';

class AdminOrderEntity extends Equatable {
  final String id;
  final String orderNumber;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? shippingAddress;
  final String totalAmount;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final String? notes;
  final int itemsCount;
  final String itemNames; // Comma-separated list of product names
  final DateTime createdAt;

  const AdminOrderEntity({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.shippingAddress,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    this.notes,
    required this.itemsCount,
    required this.itemNames,
    required this.createdAt,
  });

  /// Creates a copy of this entity with updated fields
  AdminOrderEntity copyWith({
    String? id,
    String? orderNumber,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? shippingAddress,
    String? totalAmount,
    String? status,
    String? paymentStatus,
    String? paymentMethod,
    String? notes,
    int? itemsCount,
    String? itemNames,
    DateTime? createdAt,
  }) {
    return AdminOrderEntity(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      itemsCount: itemsCount ?? this.itemsCount,
      itemNames: itemNames ?? this.itemNames,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    customerName,
    customerEmail,
    customerPhone,
    shippingAddress,
    totalAmount,
    status,
    paymentStatus,
    paymentMethod,
    notes,
    itemsCount,
    itemNames,
    createdAt,
  ];
}
