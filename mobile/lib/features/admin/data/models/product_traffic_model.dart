import 'package:mobile/features/admin/domain/entities/product_traffic_entity.dart';

class ProductTrafficModel extends ProductTrafficEntity {
  const ProductTrafficModel({
    required super.productId,
    required super.productName,
    required super.views,
  });

  factory ProductTrafficModel.fromJson(Map<String, dynamic> json) {
    return ProductTrafficModel(
      productId: json['productId'] ?? json['product_id'] ?? '',
      productName: json['productName'] ?? json['product_name'] ?? '',
      // ✅ FIXED: Handle both String and int for views
      views: _parseViews(json['views'] ?? json['value'] ?? 0),
    );
  }

  // ✅ Helper method to parse views as int
  static int _parseViews(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is String) {
      return int.tryParse(value) ?? 0;
    } else if (value is double) {
      return value.toInt();
    }
    return 0;
  }

  ProductTrafficEntity toEntity() {
    return this;
  }

  Map<String, dynamic> toJson() {
    return {'productId': productId, 'productName': productName, 'views': views};
  }
}
