// lib/features/product/presentation/blocs/banner/banner_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/common/entities/no_params.dart';
import 'package:mobile/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:mobile/features/product/domain/entities/banner.dart';
import 'package:mobile/features/product/domain/usecases/banner/get_active_banners.dart';
import 'banner_event.dart';
import 'banner_state.dart';

class BannerBloc extends Bloc<BannerEvent, BannerState> {
  final GetActiveBanners getActiveBanners;

  BannerBloc({required this.getActiveBanners}) : super(BannerInitial()) {
    on<LoadBannersEvent>(_onLoadBanners);
  }

  // banner_bloc.dart

  Future<void> _onLoadBanners(
    LoadBannersEvent event,
    Emitter<BannerState> emit,
  ) async {
    debugPrint('🔄 [BannerBloc] Loading banners...'); // ✅ Add log
    emit(BannersLoading());

    final result = await getActiveBanners(const NoParams());

    result.fold(
      (failure) {
        debugPrint('❌ [BannerBloc] Error: ${failure.message}'); // ✅ Add log
        emit(BannersError(failure.message));
      },
      (banners) {
        debugPrint(
          '✅ [BannerBloc] Loaded ${banners.length} banners',
        ); // ✅ Add log
        var filteredBanners = banners;

        if (event.filter != null) {
          filteredBanners = _applyFilter(banners, event.filter!);
        }

        emit(BannersLoaded(filteredBanners));
      },
    );
  }

  /// ✅ Filter banners based on type
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
}
