import 'package:equatable/equatable.dart';
import 'package:mobile/features/admin/domain/entities/affiliate_entity.dart';
import 'package:mobile/features/admin/domain/entities/affiliate_request_entity.dart';
import 'package:mobile/features/admin/domain/entities/promo_code_entity.dart';

abstract class AffiliateState extends Equatable {
  const AffiliateState();
  @override
  List<Object?> get props => [];
}

class AffiliateInitial extends AffiliateState {}

class AffiliateLoading extends AffiliateState {}

class AffiliateDashboardLoaded extends AffiliateState {
  final Map<String, dynamic> data;
  const AffiliateDashboardLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class AffiliateRequestsLoaded extends AffiliateState {
  final List<AffiliateRequestEntity> requests;
  const AffiliateRequestsLoaded(this.requests);
  @override
  List<Object?> get props => [requests];
}

class AffiliatesLoaded extends AffiliateState {
  final List<AffiliateEntity> affiliates;
  const AffiliatesLoaded(this.affiliates);
  @override
  List<Object?> get props => [affiliates];
}

class PromoCodesLoaded extends AffiliateState {
  final List<PromoCodeEntity> promoCodes;
  const PromoCodesLoaded(this.promoCodes);
  @override
  List<Object?> get props => [promoCodes];
}

class CommissionsLoaded extends AffiliateState {
  final Map<String, dynamic> data;
  const CommissionsLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class AffiliateOperationSuccess extends AffiliateState {
  final String message;
  const AffiliateOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class AffiliateError extends AffiliateState {
  final String message;
  const AffiliateError(this.message);
  @override
  List<Object?> get props => [message];
}

// affiliate_state.dart
class AffiliateRefreshing extends AffiliateState {
  const AffiliateRefreshing();
}

// ── Affiliate Settings ─────────────────────────────
class AffiliateSettingsLoaded extends AffiliateState {
  final Map<String, dynamic> settings;
  const AffiliateSettingsLoaded(this.settings);
  @override
  List<Object?> get props => [settings];
}

class AffiliateSettingsSaving extends AffiliateState {
  const AffiliateSettingsSaving();
}

class AffiliateSettingsSaved extends AffiliateState {
  final Map<String, dynamic> settings;
  const AffiliateSettingsSaved(this.settings);
  @override
  List<Object?> get props => [settings];
}
