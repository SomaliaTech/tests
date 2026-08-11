// lib/features/product/presentation/widgets/home/banners_carousel.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/product/domain/entities/banner.dart'
    as banner_entity;
import 'package:mobile/features/product/presentation/blocs/banner/banner_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/banner/banner_state.dart';
import 'package:mobile/features/product/presentation/screens/category_screen.dart';
import 'package:mobile/features/product/presentation/screens/category_view.dart';
import 'package:mobile/features/product/presentation/screens/product_detail_screen.dart';
import 'package:mobile/features/product/presentation/screens/product_detail_view.dart';
import 'package:mobile/features/product/presentation/widgets/home/animated_carousel.dart';
import 'package:mobile/features/product/presentation/widgets/home/discount_badge.dart';
import 'package:mobile/features/product/presentation/widgets/home/flash_sale_badge.dart';

import 'package:mobile/features/product/presentation/widgets/loading/banner_skeleton.dart';

class BannersCarousel extends StatefulWidget {
  const BannersCarousel({super.key});

  @override
  State<BannersCarousel> createState() => _BannersCarouselState();
}

class _BannersCarouselState extends State<BannersCarousel> {
  // Cache badges separately to prevent recreation
  final Map<String, Widget> _cachedBadges = {};
  List<String>? _lastBannerIds;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ REMOVED SliverToBoxAdapter wrapper — now returns a regular box widget
    return BlocBuilder<BannerBloc, BannerState>(
      builder: (context, state) {
        if (state is BannersLoading) {
          _clearCache();
          return const BannerSkeleton();
        }

        if (state is BannersLoaded || state is BannersError) {
          final banners = state is BannersLoaded
              ? state.banners
              : <banner_entity.AppBanner>[];

          final currentIds = banners.map((b) => b.id).toList();
          final bannersChanged = !_listEquals(_lastBannerIds, currentIds);

          if (bannersChanged) {
            _lastBannerIds = currentIds;
            _cachedBadges.keys
                .where((id) => !currentIds.contains(id))
                .toList()
                .forEach((id) => _cachedBadges.remove(id));
          }

          final items = banners.map((banner) {
            return CarouselItem(
              id: banner.id,
              imageUrl: banner.imageUrl,
              title: banner.title,
              subtitle: _buildSubtitle(banner) ?? banner.subtitle,
              buttonText: banner.buttonText,
              backgroundColor: banner.backgroundColor != null
                  ? Color(_parseHexColor(banner.backgroundColor!))
                  : null,
              backgroundGradient: _buildGradient(banner),
              customBadge: _buildBadges(banner),
              onTap: () => _handleBannerTap(context, banner),
            );
          }).toList();

          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AnimatedCarousel(
              items: items.isEmpty ? _getDefaultCarouselItems() : items,
              height: 200,
              autoPlayInterval: const Duration(seconds: 4),
              showIndicators: true,
              showArrows: false,
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _clearCache() {
    _lastBannerIds = null;
    _cachedBadges.clear();
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ==========================================
  // ✅ NEW: Build both badges side by side
  // ==========================================
  Widget? _buildBadges(banner_entity.AppBanner banner) {
    final List<Widget> badges = [];

    // Add Flash Sale badge if applicable
    if (banner.isFlashSale && banner.isFlashSaleActive) {
      final flashBadge = _getOrCreateFlashSaleBadge(banner);
      if (flashBadge != null) {
        badges.add(flashBadge);
      }
    }

    // Add Discount badge if applicable
    if (banner.hasDiscount && banner.isDiscountActive) {
      badges.add(_buildDiscountBadge(banner));
    }

    // Return null if no badges
    if (badges.isEmpty) return null;

    // If only one badge, return it directly
    if (badges.length == 1) return badges.first;

    // If multiple badges, show them in a Row
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: badges
          .map(
            (badge) =>
                Padding(padding: const EdgeInsets.only(left: 8), child: badge),
          )
          .toList(),
    );
  }

  // ==========================================
  // FLASH SALE BADGE (Cached)
  // ==========================================
  Widget? _getOrCreateFlashSaleBadge(banner_entity.AppBanner banner) {
    if (banner.flashSaleEndTime == null) return null;

    // Return cached badge if exists
    if (_cachedBadges.containsKey('flash_${banner.id}')) {
      return _cachedBadges['flash_${banner.id}'];
    }

    // Create new badge and cache it
    final badge = FlashSaleBadge(
      key: ValueKey('flash_${banner.id}'),
      endTime: banner.flashSaleEndTime!,
    );
    _cachedBadges['flash_${banner.id}'] = badge;
    return badge;
  }

  // ==========================================
  // DISCOUNT BADGE
  // ==========================================
  Widget _buildDiscountBadge(banner_entity.AppBanner banner) {
    return DiscountBadge(
      percentage: banner.discountPercentage,
      amount: banner.discountAmount,
    );
  }

  LinearGradient? _buildGradient(banner_entity.AppBanner banner) {
    if (banner.gradientStart == null || banner.gradientEnd == null) return null;
    return LinearGradient(
      colors: [
        Color(_parseHexColor(banner.gradientStart!)),
        Color(_parseHexColor(banner.gradientEnd!)),
      ],
    );
  }

  String? _buildSubtitle(banner_entity.AppBanner banner) {
    // Priority: Flash Sale > Discount > Default subtitle
    if (banner.isFlashSale && banner.isFlashSaleActive) {
      final price = banner.flashSalePrice?.toStringAsFixed(2) ?? '0.00';
      return '🔥 Flash Sale - \$$price';
    }
    if (banner.hasDiscount && banner.isDiscountActive) {
      if (banner.discountPercentage != null) {
        return '${banner.discountPercentage!.toInt()}% OFF';
      }
      if (banner.discountAmount != null) {
        return '\$${banner.discountAmount!.toStringAsFixed(2)} OFF';
      }
    }
    return banner.subtitle;
  }

  void _handleBannerTap(BuildContext context, banner_entity.AppBanner banner) {
    final link = banner.actionLink;
    if (link == null || link.isEmpty) return;

    if (link.startsWith('/products/category/')) {
      final categoryId = link.replaceAll('/products/category/', '');

      // ✅ Use MaterialPageRoute instead of pushNamed
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryView(
            categoryId: categoryId,
            // discountCode: banner.discountCode,
          ),
        ),
      );
    } else if (link.startsWith('/products/')) {
      final productId = link.replaceAll('/products/', '');

      // ✅ Use MaterialPageRoute instead of pushNamed
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(
            productId: productId,
            // flashSalePrice: banner.flashSalePrice,
          ),
        ),
      );
    }
  }

  int _parseHexColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return int.parse(hex, radix: 16);
  }

  List<CarouselItem> _getDefaultCarouselItems() {
    return [
      CarouselItem(
        id: 'default-1',
        imageUrl:
            'https://images.unsplash.com/photo-1607083206968-13611e3d76db?w=800',
        title: 'Welcome to Our Store',
        subtitle: 'Discover amazing products',
        buttonText: 'Shop Now',
        backgroundGradient: const LinearGradient(
          colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
        ),
        onTap: () {},
      ),
      CarouselItem(
        id: 'default-2',
        imageUrl:
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800',
        title: 'New Arrivals',
        subtitle: 'Check out our latest collection',
        buttonText: 'Explore',
        backgroundGradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        onTap: () {},
      ),
    ];
  }
}
