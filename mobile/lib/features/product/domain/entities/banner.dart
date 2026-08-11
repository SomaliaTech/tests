// lib/features/product/domain/entities/banner.dart
import 'package:equatable/equatable.dart';

class AppBanner extends Equatable {
  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? buttonText;
  final String? actionLink;
  final String? backgroundColor;
  final String? gradientStart;
  final String? gradientEnd;
  final bool isActive;
  final int order;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ✅ Discount fields
  final bool hasDiscount;
  final double? discountPercentage;
  final double? discountAmount;
  final String? discountCode;
  final DateTime? discountStartDate;
  final DateTime? discountEndDate;

  // ✅ Flash sale fields
  final bool isFlashSale;
  final DateTime? flashSaleStartTime;
  final DateTime? flashSaleEndTime;
  final int? flashSaleQuantity;
  final double? flashSalePrice;

  const AppBanner({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.buttonText,
    this.actionLink,
    this.backgroundColor,
    this.gradientStart,
    this.gradientEnd,
    required this.isActive,
    required this.order,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.hasDiscount = false,
    this.discountPercentage,
    this.discountAmount,
    this.discountCode,
    this.discountStartDate,
    this.discountEndDate,
    this.isFlashSale = false,
    this.flashSaleStartTime,
    this.flashSaleEndTime,
    this.flashSaleQuantity,
    this.flashSalePrice,
  });

  // ✅ Helper getters
  bool get isDiscountActive {
    if (!hasDiscount) return false;
    final now = DateTime.now();
    if (discountStartDate != null && now.isBefore(discountStartDate!))
      return false;
    if (discountEndDate != null && now.isAfter(discountEndDate!)) return false;
    return true;
  }

  bool get isFlashSaleActive {
    if (!isFlashSale) return false;
    final now = DateTime.now();
    if (flashSaleStartTime != null && now.isBefore(flashSaleStartTime!))
      return false;
    if (flashSaleEndTime != null && now.isAfter(flashSaleEndTime!))
      return false;
    return true;
  }

  Duration? get flashSaleTimeRemaining {
    if (!isFlashSaleActive || flashSaleEndTime == null) return null;
    final remaining = flashSaleEndTime!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    imageUrl,
    buttonText,
    actionLink,
    backgroundColor,
    gradientStart,
    gradientEnd,
    isActive,
    order,
    createdBy,
    createdAt,
    updatedAt,
    hasDiscount,
    discountPercentage,
    discountAmount,
    discountCode,
    discountStartDate,
    discountEndDate,
    isFlashSale,
    flashSaleStartTime,
    flashSaleEndTime,
    flashSaleQuantity,
    flashSalePrice,
  ];

  AppBanner copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? buttonText,
    String? actionLink,
    String? backgroundColor,
    String? gradientStart,
    String? gradientEnd,
    bool? isActive,
    int? order,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasDiscount,
    double? discountPercentage,
    double? discountAmount,
    String? discountCode,
    DateTime? discountStartDate,
    DateTime? discountEndDate,
    bool? isFlashSale,
    DateTime? flashSaleStartTime,
    DateTime? flashSaleEndTime,
    int? flashSaleQuantity,
    double? flashSalePrice,
    bool clearDiscountPercentage = false,
    bool clearDiscountAmount = false,
    bool clearDiscountCode = false,
    bool clearDiscountStartDate = false,
    bool clearDiscountEndDate = false,
    bool clearFlashSaleStartTime = false,
    bool clearFlashSaleEndTime = false,
    bool clearFlashSaleQuantity = false,
    bool clearFlashSalePrice = false,
  }) {
    return AppBanner(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      buttonText: buttonText ?? this.buttonText,
      actionLink: actionLink ?? this.actionLink,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasDiscount: hasDiscount ?? this.hasDiscount,
      discountPercentage: clearDiscountPercentage
          ? null
          : (discountPercentage ?? this.discountPercentage),
      discountAmount: clearDiscountAmount
          ? null
          : (discountAmount ?? this.discountAmount),
      discountCode: clearDiscountCode
          ? null
          : (discountCode ?? this.discountCode),
      discountStartDate: clearDiscountStartDate
          ? null
          : (discountStartDate ?? this.discountStartDate),
      discountEndDate: clearDiscountEndDate
          ? null
          : (discountEndDate ?? this.discountEndDate),
      isFlashSale: isFlashSale ?? this.isFlashSale,
      flashSaleStartTime: clearFlashSaleStartTime
          ? null
          : (flashSaleStartTime ?? this.flashSaleStartTime),
      flashSaleEndTime: clearFlashSaleEndTime
          ? null
          : (flashSaleEndTime ?? this.flashSaleEndTime),
      flashSaleQuantity: clearFlashSaleQuantity
          ? null
          : (flashSaleQuantity ?? this.flashSaleQuantity),
      flashSalePrice: clearFlashSalePrice
          ? null
          : (flashSalePrice ?? this.flashSalePrice),
    );
  }
}
