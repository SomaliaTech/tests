import 'package:equatable/equatable.dart';

class ProductTrafficEntity extends Equatable {
  final String productId;
  final String productName;
  final int views;

  const ProductTrafficEntity({
    required this.productId,
    required this.productName,
    required this.views,
  });

  @override
  List<Object?> get props => [productId, productName, views];
}
