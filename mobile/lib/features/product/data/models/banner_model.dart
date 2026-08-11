// lib/features/product/data/models/banner_model.dart
import 'package:mobile/features/product/domain/entities/banner.dart';

class BannerModel extends AppBanner {
  const BannerModel({
    required super.id,
    required super.title,
    super.subtitle,
    required super.imageUrl,
    super.buttonText,
    super.actionLink,
    super.backgroundColor,
    super.gradientStart,
    super.gradientEnd,
    required super.isActive,
    required super.order,
    super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.hasDiscount = false,
    super.discountPercentage,
    super.discountAmount,
    super.discountCode,
    super.discountStartDate,
    super.discountEndDate,
    super.isFlashSale = false,
    super.flashSaleStartTime,
    super.flashSaleEndTime,
    super.flashSaleQuantity,
    super.flashSalePrice,
  });
  // lib/features/product/data/models/banner_model.dart

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      imageUrl: json['imageUrl'] as String,
      buttonText: json['buttonText'] as String?,
      actionLink: json['actionLink'] as String?,
      backgroundColor: json['backgroundColor'] as String?,
      gradientStart: json['gradientStart'] as String?,
      gradientEnd: json['gradientEnd'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),

      // ✅ Handle both number and string for decimal fields
      hasDiscount: json['hasDiscount'] as bool? ?? false,
      discountPercentage: _parseDouble(json['discountPercentage']),
      discountAmount: _parseDouble(json['discountAmount']),
      discountCode: json['discountCode'] as String?,
      discountStartDate: json['discountStartDate'] != null
          ? DateTime.parse(json['discountStartDate'] as String)
          : null,
      discountEndDate: json['discountEndDate'] != null
          ? DateTime.parse(json['discountEndDate'] as String)
          : null,

      isFlashSale: json['isFlashSale'] as bool? ?? false,
      flashSaleStartTime: json['flashSaleStartTime'] != null
          ? DateTime.parse(json['flashSaleStartTime'] as String)
          : null,
      flashSaleEndTime: json['flashSaleEndTime'] != null
          ? DateTime.parse(json['flashSaleEndTime'] as String)
          : null,
      flashSaleQuantity: json['flashSaleQuantity'] as int?,
      flashSalePrice: _parseDouble(json['flashSalePrice']),
    );
  }

  /// ✅ Helper to parse double from both int and double
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'buttonText': buttonText,
      'actionLink': actionLink,
      'backgroundColor': backgroundColor,
      'gradientStart': gradientStart,
      'gradientEnd': gradientEnd,
      'isActive': isActive,
      'order': order,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),

      // ✅ Serialize discount fields
      'hasDiscount': hasDiscount,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      'discountCode': discountCode,
      'discountStartDate': discountStartDate?.toIso8601String(),
      'discountEndDate': discountEndDate?.toIso8601String(),

      // ✅ Serialize flash sale fields
      'isFlashSale': isFlashSale,
      'flashSaleStartTime': flashSaleStartTime?.toIso8601String(),
      'flashSaleEndTime': flashSaleEndTime?.toIso8601String(),
      'flashSaleQuantity': flashSaleQuantity,
      'flashSalePrice': flashSalePrice,
    };
  }

  AppBanner toEntity() {
    return AppBanner(
      id: id,
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
      buttonText: buttonText,
      actionLink: actionLink,
      backgroundColor: backgroundColor,
      gradientStart: gradientStart,
      gradientEnd: gradientEnd,
      isActive: isActive,
      order: order,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      hasDiscount: hasDiscount,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      discountCode: discountCode,
      discountStartDate: discountStartDate,
      discountEndDate: discountEndDate,
      isFlashSale: isFlashSale,
      flashSaleStartTime: flashSaleStartTime,
      flashSaleEndTime: flashSaleEndTime,
      flashSaleQuantity: flashSaleQuantity,
      flashSalePrice: flashSalePrice,
    );
  }
}
