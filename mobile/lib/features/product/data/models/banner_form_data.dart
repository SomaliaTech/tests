// lib/features/admin/presentation/models/banner_form_data.dart

import 'package:mobile/features/product/domain/entities/banner.dart';

class BannerFormData {
  // ==========================================
  // ✅ WRAP THE ENTITY - No duplication!
  // ==========================================
  AppBanner _banner;

  // ==========================================
  // ✅ FORM-SPECIFIC FIELDS ONLY
  // ==========================================
  bool useImageUpload;
  String? uploadedImageUrl;
  String? localImagePath;
  bool useGradient; // UI toggle, not stored in entity directly

  // ==========================================
  // CONSTRUCTORS
  // ==========================================

  /// Create for new banner
  BannerFormData.create()
    : _banner = AppBanner(
        id: '',
        title: '',
        imageUrl: '',
        isActive: true,
        order: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      useImageUpload = true,
      uploadedImageUrl = null,
      localImagePath = null,
      useGradient = true;

  /// Create from existing banner (for editing)
  BannerFormData.fromBanner(AppBanner banner)
    : _banner = banner,
      useImageUpload = false,
      uploadedImageUrl = null,
      localImagePath = null,
      useGradient = banner.gradientStart != null && banner.gradientEnd != null;

  // ==========================================
  // ✅ GETTERS - Direct access to entity fields
  // ==========================================

  // Basic info
  String get title => _banner.title;
  set title(String value) => _banner = _banner.copyWith(title: value);

  String? get subtitle => _banner.subtitle;
  set subtitle(String? value) => _banner = _banner.copyWith(subtitle: value);

  String? get imageUrl => _banner.imageUrl;
  set imageUrl(String? value) =>
      _banner = _banner.copyWith(imageUrl: value ?? '');

  String? get buttonText => _banner.buttonText;
  set buttonText(String? value) =>
      _banner = _banner.copyWith(buttonText: value);

  String? get actionLink => _banner.actionLink;
  set actionLink(String? value) =>
      _banner = _banner.copyWith(actionLink: value);

  // Colors
  String? get backgroundColor => _banner.backgroundColor;
  set backgroundColor(String? value) =>
      _banner = _banner.copyWith(backgroundColor: value);

  String? get gradientStart => _banner.gradientStart ?? '#2ED573';
  set gradientStart(String? value) =>
      _banner = _banner.copyWith(gradientStart: value);

  String? get gradientEnd => _banner.gradientEnd ?? '#1ABC9C';
  set gradientEnd(String? value) =>
      _banner = _banner.copyWith(gradientEnd: value);

  // Settings
  bool get isActive => _banner.isActive;
  set isActive(bool value) => _banner = _banner.copyWith(isActive: value);

  int get order => _banner.order;
  set order(int value) => _banner = _banner.copyWith(order: value);

  // Discount
  bool get hasDiscount => _banner.hasDiscount;
  set hasDiscount(bool value) => _banner = _banner.copyWith(hasDiscount: value);

  double? get discountPercentage => _banner.discountPercentage;
  set discountPercentage(double? value) =>
      _banner = _banner.copyWith(discountPercentage: value);

  double? get discountAmount => _banner.discountAmount;
  set discountAmount(double? value) =>
      _banner = _banner.copyWith(discountAmount: value);

  String? get discountCode => _banner.discountCode;
  set discountCode(String? value) =>
      _banner = _banner.copyWith(discountCode: value);

  DateTime? get discountStartDate => _banner.discountStartDate;
  set discountStartDate(DateTime? value) =>
      _banner = _banner.copyWith(discountStartDate: value);

  DateTime? get discountEndDate => _banner.discountEndDate;
  set discountEndDate(DateTime? value) =>
      _banner = _banner.copyWith(discountEndDate: value);

  // Flash Sale
  bool get isFlashSale => _banner.isFlashSale;
  set isFlashSale(bool value) => _banner = _banner.copyWith(isFlashSale: value);

  DateTime? get flashSaleStartTime => _banner.flashSaleStartTime;
  set flashSaleStartTime(DateTime? value) =>
      _banner = _banner.copyWith(flashSaleStartTime: value);

  DateTime? get flashSaleEndTime => _banner.flashSaleEndTime;
  set flashSaleEndTime(DateTime? value) =>
      _banner = _banner.copyWith(flashSaleEndTime: value);

  int? get flashSaleQuantity => _banner.flashSaleQuantity;
  set flashSaleQuantity(int? value) =>
      _banner = _banner.copyWith(flashSaleQuantity: value);

  double? get flashSalePrice => _banner.flashSalePrice;
  set flashSalePrice(double? value) =>
      _banner = _banner.copyWith(flashSalePrice: value);

  // ==========================================
  // ✅ COMPUTED PROPERTIES (from entity)
  // ==========================================

  bool get isDiscountActive => _banner.isDiscountActive;
  bool get isFlashSaleActive => _banner.isFlashSaleActive;
  Duration? get flashSaleTimeRemaining => _banner.flashSaleTimeRemaining;

  /// Get the effective image URL for preview
  String? get effectiveImageUrl {
    if (useImageUpload) {
      if (uploadedImageUrl != null) return uploadedImageUrl;
      if (localImagePath != null) return 'file://$localImagePath';
      return null;
    }
    return _banner.imageUrl.isNotEmpty ? _banner.imageUrl : null;
  }

  /// Get discount display text
  String? get discountDisplayText {
    if (!_banner.hasDiscount) return null;
    if (_banner.discountPercentage != null) {
      return '${_banner.discountPercentage!.toInt()}% OFF';
    }
    if (_banner.discountAmount != null) {
      return '\$${_banner.discountAmount!.toStringAsFixed(2)} OFF';
    }
    return null;
  }

  // ==========================================
  // ✅ CONVERSION METHODS
  // ==========================================

  /// Get the underlying entity (for display)
  AppBanner get banner => _banner;

  /// Convert to API JSON
  /// ✅ Convert to API JSON - FIXED: Numbers should be numbers, not strings
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle?.isNotEmpty == true ? subtitle : null,
      'imageUrl': useImageUpload ? uploadedImageUrl : imageUrl,
      'buttonText': buttonText?.isNotEmpty == true ? buttonText : null,
      'actionLink': actionLink?.isNotEmpty == true ? actionLink : null,
      'backgroundColor': useGradient ? null : backgroundColor,
      'gradientStart': useGradient ? gradientStart : null,
      'gradientEnd': useGradient ? gradientEnd : null,
      'isActive': isActive,
      'order': order, // ✅ Already int
      // Discount
      'hasDiscount': hasDiscount,
      'discountPercentage': hasDiscount
          ? discountPercentage
          : null, // ✅ Send as num, not String
      'discountAmount': hasDiscount
          ? discountAmount
          : null, // ✅ Send as num, not String
      'discountCode': hasDiscount && discountCode?.isNotEmpty == true
          ? discountCode
          : null,
      'discountStartDate': hasDiscount
          ? discountStartDate?.toIso8601String()
          : null,
      'discountEndDate': hasDiscount
          ? discountEndDate?.toIso8601String()
          : null,

      // Flash Sale
      'isFlashSale': isFlashSale,
      'flashSaleStartTime': isFlashSale
          ? flashSaleStartTime?.toIso8601String()
          : null,
      'flashSaleEndTime': isFlashSale
          ? flashSaleEndTime?.toIso8601String()
          : null,
      'flashSaleQuantity': isFlashSale
          ? flashSaleQuantity
          : null, // ✅ Send as int, not String
      'flashSalePrice': isFlashSale
          ? flashSalePrice
          : null, // ✅ Send as num, not String
    };
  }
  // ==========================================
  // ✅ VALIDATION
  // ==========================================

  String? validate() {
    if (_banner.title.trim().isEmpty) {
      return 'Title is required';
    }

    final imgUrl = useImageUpload ? uploadedImageUrl : _banner.imageUrl;
    if (imgUrl == null || imgUrl.isEmpty) {
      return 'Please upload an image or provide an image URL';
    }

    // Validate discount
    if (_banner.hasDiscount) {
      if (_banner.discountPercentage == null &&
          _banner.discountAmount == null) {
        return 'Discount requires either percentage or amount';
      }
      if (_banner.discountPercentage != null &&
          _banner.discountAmount != null) {
        return 'Cannot have both discount percentage and amount';
      }
      if (_banner.discountPercentage != null &&
          (_banner.discountPercentage! < 0 ||
              _banner.discountPercentage! > 100)) {
        return 'Discount percentage must be between 0 and 100';
      }
      if (_banner.discountStartDate != null &&
          _banner.discountEndDate != null) {
        if (_banner.discountEndDate!.isBefore(_banner.discountStartDate!)) {
          return 'Discount end date must be after start date';
        }
      }
    }

    // Validate flash sale
    if (_banner.isFlashSale) {
      if (_banner.flashSaleStartTime == null ||
          _banner.flashSaleEndTime == null) {
        return 'Flash sale requires start and end times';
      }
      if (_banner.flashSaleEndTime!.isBefore(_banner.flashSaleStartTime!)) {
        return 'Flash sale end time must be after start time';
      }
      if (_banner.flashSalePrice == null || _banner.flashSalePrice! <= 0) {
        return 'Flash sale requires a valid price';
      }
      if (_banner.flashSaleQuantity != null && _banner.flashSaleQuantity! < 1) {
        return 'Flash sale quantity must be at least 1';
      }
    }

    return null;
  }

  bool get isValid => validate() == null;

  @override
  String toString() {
    return 'BannerFormData(title: ${_banner.title}, hasDiscount: ${_banner.hasDiscount}, isFlashSale: ${_banner.isFlashSale})';
  }
}
