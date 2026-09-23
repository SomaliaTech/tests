import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/affiliate/domain/repositories/affiliate_user_repository.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_event.dart';
import 'package:mobile/features/affiliate/presentation/bloc/affiliate_user/affiliate_user_state.dart';

class AffiliateUserBloc extends Bloc<AffiliateUserEvent, AffiliateUserState> {
  final AffiliateUserRepository repository;
  final StorageService storage; // ✅ add this
  AffiliateUserBloc({required this.repository, required this.storage})
    : super(AffiliateUserInitial()) {
    on<ApplyAffiliateEvent>(_onApply);
    on<FetchMyAffiliateProfileEvent>(_onFetchProfile);
    on<FetchMyDashboardStatsEvent>(_onFetchStats);
    on<FetchMyPromoCodesEvent>(_onFetchPromoCodes);
    on<CreateMyPromoCodeEvent>(_onCreatePromoCode);
    on<ToggleMyPromoCodeEvent>(_onTogglePromoCode);
    on<DeleteMyPromoCodeEvent>(_onDeletePromoCode);
    on<FetchMyCommissionsEvent>(_onFetchCommissions);
  }

  // -----------------------------------------------------------------
  // Apply
  // -----------------------------------------------------------------
  Future<void> _onApply(
    ApplyAffiliateEvent event,
    Emitter<AffiliateUserState> emit,
  ) async {
    debugPrint('📤 [Apply] Submitting application...');
    emit(AffiliateUserLoading());
    try {
      await repository.applyForAffiliate(
        businessName: event.businessName,
        description: event.description,
        phoneNumber: event.phoneNumber,
        socialMediaLinks: event.socialMediaLinks,
        expectedAudience: event.expectedAudience,
      );
      debugPrint('✅ [Apply] Application accepted by server');
      emit(
        const AffiliateUserOperationSuccess(
          'Application submitted! An admin will review it shortly.',
        ),
      );
    } catch (e) {
      debugPrint('❌ [Apply] Failed: $e');
      emit(AffiliateUserError(e.toString()));
    }
  }

  // -----------------------------------------------------------------
  // Profile
  // -----------------------------------------------------------------
  Future<void> _onFetchProfile(
    FetchMyAffiliateProfileEvent event,
    Emitter<AffiliateUserState> emit,
  ) async {
    emit(AffiliateUserLoading());
    try {
      final profile = await repository.getMyAffiliateProfile();
      emit(MyAffiliateProfileLoaded(profile));
    } catch (e) {
      emit(AffiliateUserError(e.toString()));
    }
  }

  // -----------------------------------------------------------------
  // Stats
  // -----------------------------------------------------------------
  Future<void> _onFetchStats(
    FetchMyDashboardStatsEvent event,
    Emitter<AffiliateUserState> emit,
  ) async {
    emit(AffiliateUserLoading());
    try {
      final stats = await repository.getMyDashboardStats();
      emit(MyDashboardStatsLoaded(stats));

      // ✅ Persist for instant next render
      await storage.saveAffiliateStatus(
        isAffiliate:
            stats['isAffiliate'] == true ||
            stats['uniqueCode'] != null ||
            stats['status'] == 'ACTIVE',
        status: (stats['status'] ?? 'NONE').toString(),
      );
    } catch (e) {
      emit(AffiliateUserError(e.toString()));
    }
  }

  // -----------------------------------------------------------------
  // Promo codes
  // -----------------------------------------------------------------
  Future<void> _onFetchPromoCodes(
    FetchMyPromoCodesEvent event,
    Emitter<AffiliateUserState> emit,
  ) async {
    emit(AffiliateUserLoading());
    try {
      final codes = await repository.getMyPromoCodes();
      emit(MyPromoCodesLoaded(codes));
    } catch (e) {
      emit(AffiliateUserError(e.toString()));
    }
  }

  Future<void> _onCreatePromoCode(
    CreateMyPromoCodeEvent event,
    Emitter<AffiliateUserState> emit,
  ) async {
    try {
      await repository.createMyPromoCode(event.data);
      emit(
        const AffiliateUserOperationSuccess('Promo code created successfully!'),
      );
      add(const FetchMyPromoCodesEvent());
    } catch (e) {
      emit(AffiliateUserError(e.toString()));
    }
  }

  Future<void> _onTogglePromoCode(
    ToggleMyPromoCodeEvent event,
    Emitter<AffiliateUserState> emit,
  ) async {
    try {
      await repository.toggleMyPromoCode(event.promoCodeId, event.isActive);
      emit(
        AffiliateUserOperationSuccess(
          event.isActive ? 'Code activated' : 'Code deactivated',
        ),
      );
      add(const FetchMyPromoCodesEvent());
    } catch (e) {
      emit(AffiliateUserError(e.toString()));
    }
  }

  Future<void> _onDeletePromoCode(
    DeleteMyPromoCodeEvent event,
    Emitter<AffiliateUserState> emit,
  ) async {
    emit(AffiliateUserLoading());
    try {
      await repository.deleteMyPromoCode(event.promoCodeId);
      emit(
        const AffiliateUserOperationSuccess('Promo code deleted successfully'),
      );
      add(const FetchMyPromoCodesEvent());
    } catch (e) {
      emit(AffiliateUserError(e.toString()));
    }
  }

  // -----------------------------------------------------------------
  // Commissions
  // -----------------------------------------------------------------
  Future<void> _onFetchCommissions(
    FetchMyCommissionsEvent event,
    Emitter<AffiliateUserState> emit,
  ) async {
    emit(AffiliateUserLoading());
    try {
      final commissions = await repository.getMyCommissions(
        status: event.status,
      );
      emit(MyCommissionsLoaded(commissions));
    } catch (e) {
      emit(AffiliateUserError(e.toString()));
    }
  }
}
