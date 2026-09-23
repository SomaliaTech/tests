import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/admin/domain/repositories/affiliate_repository.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_event.dart';
import 'package:mobile/features/admin/presentation/bloc/affiliate/affiliate_state.dart';

class AffiliateBloc extends Bloc<AffiliateEvent, AffiliateState> {
  final AffiliateRepository repository;

  AffiliateBloc({required this.repository}) : super(AffiliateInitial()) {
    on<FetchAffiliateDashboardEvent>(_onFetchDashboard);
    on<FetchAffiliateRequestsEvent>(_onFetchRequests);
    on<ApproveAffiliateRequestEvent>(_onApprove);
    on<RejectAffiliateRequestEvent>(_onReject);
    on<FetchAllAffiliatesEvent>(_onFetchAffiliates);
    on<UpdateAffiliateEvent>(_onUpdateAffiliate);
    on<FetchAllPromoCodesEvent>(_onFetchPromoCodes);
    on<CreateSystemPromoCodeEvent>(_onCreateSystemPromoCode);
    on<AdminUpdatePromoCodeEvent>(_onAdminUpdatePromoCode);
    on<AdminDeletePromoCodeEvent>(_onAdminDeletePromoCode);
    on<FetchAllCommissionsEvent>(_onFetchCommissions);
    on<PayCommissionsEvent>(_onPayCommissions);
    on<FetchAffiliateSettingsEvent>(_onFetchSettings);
    on<SaveAffiliateSettingsEvent>(_onSaveSettings);
  }

  Future<void> _onFetchSettings(
    FetchAffiliateSettingsEvent event,
    Emitter<AffiliateState> emit,
  ) async {
    emit(AffiliateLoading());
    try {
      final settings = await repository.getAffiliateSettings();
      emit(AffiliateSettingsLoaded(settings));
    } catch (e) {
      emit(AffiliateError(e.toString()));
    }
  }

  Future<void> _onSaveSettings(
    SaveAffiliateSettingsEvent event,
    Emitter<AffiliateState> emit,
  ) async {
    emit(const AffiliateSettingsSaving());
    try {
      final result = await repository.updateAffiliateSettings(event.data);
      final settings =
          (result['settings'] as Map<String, dynamic>?) ?? event.data;
      emit(AffiliateSettingsSaved(settings));
    } catch (e) {
      emit(AffiliateError(e.toString()));
    }
  }

  // ------------------------------
  // Dashboard
  // ------------------------------
  Future<void> _onFetchDashboard(
    FetchAffiliateDashboardEvent event,
    Emitter<AffiliateState> emit,
  ) async {
    if (kDebugMode) debugPrint('🚀 [AdminBloc] Fetch dashboard');
    emit(AffiliateLoading());
    try {
      final data = await repository.getAffiliateDashboard();
      emit(AffiliateDashboardLoaded(data));
    } catch (e, st) {
      if (kDebugMode) debugPrint('❌ [AdminBloc] $e\n$st');
      emit(AffiliateError(e.toString()));
    }
  }

  // ------------------------------
  // Requests
  // ------------------------------
  Future<void> _onFetchRequests(
    FetchAffiliateRequestsEvent event,
    Emitter<AffiliateState> emit,
  ) async {
    emit(AffiliateLoading());
    try {
      final requests = await repository.getAffiliateRequests(
        status: event.status,
      );
      emit(AffiliateRequestsLoaded(requests));
    } catch (e) {
      emit(AffiliateError(e.toString()));
    }
  }

  Future<void> _onApprove(
    ApproveAffiliateRequestEvent event,
    Emitter<AffiliateState> emit,
  ) async {
    try {
      await repository.approveAffiliateRequest(
        event.requestId,
        commissionRate: event.commissionRate,
      );
      emit(const AffiliateOperationSuccess('Affiliate approved successfully'));
      add(const FetchAffiliateRequestsEvent());
      add(const FetchAffiliateDashboardEvent());
    } catch (e) {
      emit(AffiliateError(e.toString()));
    }
  }

  Future<void> _onReject(
    RejectAffiliateRequestEvent event,
    Emitter<AffiliateState> emit,
  ) async {
    try {
      await repository.rejectAffiliateRequest(event.requestId, event.reason);
      emit(const AffiliateOperationSuccess('Affiliate rejected'));
      add(const FetchAffiliateRequestsEvent());
      add(const FetchAffiliateDashboardEvent());
    } catch (e) {
      emit(AffiliateError(e.toString()));
    }
  }

  // ------------------------------
  // Affiliates
  // ------------------------------
  Future<void> _onFetchAffiliates(
    FetchAllAffiliatesEvent event,
    Emitter<AffiliateState> emit,
  ) async {
    emit(AffiliateLoading());
    try {
      final affiliates = await repository.getAllAffiliates(
        status: event.status,
        search: event.search,
      );
      emit(AffiliatesLoaded(affiliates));
    } catch (e) {
      emit(AffiliateError(e.toString()));
    }
  }

  Future<void> _onUpdateAffiliate(
    UpdateAffiliateEvent event,
    Emitter<AffiliateState> emit,
  ) async {
    try {
      await repository.updateAffiliate(
        event.affiliateId,
        commissionRate: event.commissionRate,
        status: event.status,
      );
      emit(const AffiliateOperationSuccess('Affiliate updated'));
      add(const FetchAllAffiliatesEvent());
    } catch (e) {
      emit(AffiliateError(e.toString()));
    }
  }

  // ------------------------------
  // Promo codes (admin)
  // ------------------------------
  Future<void> _onFetchPromoCodes(
    FetchAllPromoCodesEvent event,
    Emitter<AffiliateState> emit,
  ) async {
    // ✅ If we already have data, emit Refreshing instead of Loading
    final current = state;
    if (current is PromoCodesLoaded) {
      emit(const AffiliateRefreshing());
    } else {
      emit(AffiliateLoading());
    }
    try {
      final codes = await repository.getAllPromoCodes(
        type: event.type,
        isActive: event.isActive,
      );
      emit(PromoCodesLoaded(codes));
    } catch (e) {
      emit(AffiliateError(e.toString()));
    }
  }

  Future<void> _onCreateSystemPromoCode(
    CreateSystemPromoCodeEvent event,
    Emitter<AffiliateState> emit,
  ) async {
    try {
      await repository.createSystemPromoCode(event.data);
      emit(const AffiliateOperationSuccess('Promo code created'));
      add(const FetchAllPromoCodesEvent());
    } catch (e) {
      emit(AffiliateError(e.toString()));
    }
  }

  Future<void> _onAdminUpdatePromoCode(
    AdminUpdatePromoCodeEvent event,
    Emitter<AffiliateState> emit,
  ) async {
    emit(AffiliateLoading()); // 👈 ADD THIS
    try {
      await repository.updatePromoCodeByAdmin(event.promoCodeId, event.data);
      emit(const AffiliateOperationSuccess('Promo code updated successfully!'));
      add(const FetchAllPromoCodesEvent());
    } catch (e) {
      emit(AffiliateError(e.toString()));
    }
  }

  Future<void> _onAdminDeletePromoCode(
    AdminDeletePromoCodeEvent event,
    Emitter<AffiliateState> emit,
  ) async {
    emit(AffiliateLoading());
    try {
      await repository.deletePromoCodeByAdmin(event.promoCodeId);
      emit(const AffiliateOperationSuccess('Promo code deleted successfully'));
      add(const FetchAllPromoCodesEvent());
    } catch (e) {
      emit(AffiliateError(e.toString()));
    }
  }

  // ------------------------------
  // Commissions (admin)
  // ------------------------------
  Future<void> _onFetchCommissions(
    FetchAllCommissionsEvent event,
    Emitter<AffiliateState> emit,
  ) async {
    emit(AffiliateLoading());
    try {
      final data = await repository.getAllCommissions(
        status: event.status,
        affiliateId: event.affiliateId,
      );
      emit(CommissionsLoaded(data));
    } catch (e) {
      emit(AffiliateError(e.toString()));
    }
  }

  Future<void> _onPayCommissions(
    PayCommissionsEvent event,
    Emitter<AffiliateState> emit,
  ) async {
    try {
      await repository.payCommissions(
        event.commissionIds,
        paymentNote: event.paymentNote,
      );
      emit(const AffiliateOperationSuccess('Commissions paid successfully'));
      add(const FetchAllCommissionsEvent());
      add(const FetchAffiliateDashboardEvent());
    } catch (e) {
      emit(AffiliateError(e.toString()));
    }
  }
}
