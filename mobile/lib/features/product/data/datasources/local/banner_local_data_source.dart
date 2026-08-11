// lib/features/product/data/datasources/local/banner_local_data_source.dart

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../domain/entities/banner.dart';
import '../../models/banner_model.dart';

abstract class BannerLocalDataSource {
  Future<void> cacheActiveBanners(List<AppBanner> banners);
  Future<List<AppBanner>> getCachedActiveBanners();
  Future<void> clearCache();
}

class BannerLocalDataSourceImpl implements BannerLocalDataSource {
  static const String _boxName = 'banners_box';
  static const String _activeKey = 'active_banners';
  static const String _timestampKey = 'banners_timestamp';

  Future<Box<String>> get _box async => await Hive.openBox<String>(_boxName);

  @override
  Future<void> cacheActiveBanners(List<AppBanner> banners) async {
    final box = await _box;
    final jsonList = banners
        .map(
          (b) => BannerModel(
            id: b.id,
            title: b.title,
            subtitle: b.subtitle,
            imageUrl: b.imageUrl,
            buttonText: b.buttonText,
            actionLink: b.actionLink,
            backgroundColor: b.backgroundColor,
            gradientStart: b.gradientStart,
            gradientEnd: b.gradientEnd,
            isActive: b.isActive,
            order: b.order,
            createdBy: b.createdBy,
            createdAt: b.createdAt,
            updatedAt: b.updatedAt,
            hasDiscount: b.hasDiscount,
            discountPercentage: b.discountPercentage,
            discountAmount: b.discountAmount,
            discountCode: b.discountCode,
            discountStartDate: b.discountStartDate,
            discountEndDate: b.discountEndDate,
            isFlashSale: b.isFlashSale,
            flashSaleStartTime: b.flashSaleStartTime,
            flashSaleEndTime: b.flashSaleEndTime,
            flashSaleQuantity: b.flashSaleQuantity,
            flashSalePrice: b.flashSalePrice,
          ).toJson(),
        )
        .toList();

    await box.put(_activeKey, jsonEncode(jsonList));
    await box.put(_timestampKey, DateTime.now().toIso8601String());
  }

  @override
  Future<List<AppBanner>> getCachedActiveBanners() async {
    final box = await _box;
    final jsonString = box.get(_activeKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => BannerModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> clearCache() async {
    final box = await _box;
    await box.clear();
  }
}
