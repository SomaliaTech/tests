import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retry/retry.dart'; // ✅ 1. Import retry package
import 'package:mobile/core/common/entities/no_params.dart';
import 'package:mobile/core/services/connectivity_service.dart';
// ❌ Removed unused import: notifications_repository_impl.dart
import 'package:mobile/features/product/domain/entities/banner.dart';
import 'package:mobile/features/product/domain/usecases/banner/get_active_banners.dart';
import 'banner_event.dart';
import 'banner_state.dart';

class BannerBloc extends Bloc<BannerEvent, BannerState> {
  final GetActiveBanners getActiveBanners;
  final ConnectivityService _connectivityService;

  BannerBloc({
    required this.getActiveBanners,
    required ConnectivityService connectivityService,
  }) : _connectivityService = connectivityService,
       super(BannerInitial()) {
    on<LoadBannersEvent>(_onLoadBanners);

    // ✅ FIX: Listen to ConnectivityService using addListener (since it's a ChangeNotifier)
    _connectivityService.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    // Only reload if we just came back online
    if (_connectivityService.status == ConnectionStatus.online) {
      debugPrint(' [BannerBloc] Internet restored, reloading banners...');
      add(LoadBannersEvent());
    }
  }

  Future<void> _onLoadBanners(
    LoadBannersEvent event,
    Emitter<BannerState> emit,
  ) async {
    debugPrint('🔄 [BannerBloc] Loading banners...');

    // Only show loading if we don't have data yet
    if (state is! BannersLoaded) {
      emit(BannersLoading());
    }

    // ✅ Retry logic for backend restarts
    final r = RetryOptions(
      maxAttempts: 3,
      delayFactor: const Duration(seconds: 2),
    );

    try {
      final banners = await r.retry(
        () async {
          final result = await getActiveBanners(const NoParams());
          return result.fold(
            (failure) => throw Exception(failure.message),
            (banners) => banners,
          );
        },
        retryIf: (e) =>
            e is SocketException ||
            e.toString().contains('Connection refused') ||
            e.toString().contains(
              '500',
            ), // Retry on 500 too (backend restarting)
      );

      debugPrint('✅ [BannerBloc] Loaded ${banners.length} banners');
      var filteredBanners = event.filter != null
          ? _applyFilter(banners, event.filter!)
          : banners;
      emit(BannersLoaded(filteredBanners));
    } catch (e) {
      debugPrint('❌ [BannerBloc] Final Error: $e');
      // Don't emit error if we already have data (show stale data instead)
      if (state is! BannersLoaded) {
        emit(
          BannersError('Failed to load banners. Please check your connection.'),
        );
      }
    }
  }

  List<AppBanner> _applyFilter(List<AppBanner> banners, BannerFilter filter) {
    switch (filter) {
      case BannerFilter.all:
        return banners;
      case BannerFilter.discountOnly:
        return banners.where((b) => b.hasDiscount).toList();
      case BannerFilter.flashSaleOnly:
        return banners.where((b) => b.isFlashSale).toList();
      case BannerFilter.activeDiscounts:
        return banners
            .where((b) => b.isDiscountActive || b.isFlashSaleActive)
            .toList();
    }
  }

  @override
  Future<void> close() {
    _connectivityService.removeListener(_onConnectivityChanged); // Cleanup
    return super.close();
  }
}
