import 'package:equatable/equatable.dart';

abstract class AffiliateEvent extends Equatable {
  const AffiliateEvent();
  @override
  List<Object?> get props => [];
}

// Dashboard
class FetchAffiliateDashboardEvent extends AffiliateEvent {
  const FetchAffiliateDashboardEvent();
}

// Requests
class FetchAffiliateRequestsEvent extends AffiliateEvent {
  final String? status;
  const FetchAffiliateRequestsEvent({this.status});
  @override
  List<Object?> get props => [status];
}

class ApproveAffiliateRequestEvent extends AffiliateEvent {
  final String requestId;
  final double? commissionRate;
  const ApproveAffiliateRequestEvent(this.requestId, {this.commissionRate});
  @override
  List<Object?> get props => [requestId, commissionRate];
}

class RejectAffiliateRequestEvent extends AffiliateEvent {
  final String requestId;
  final String reason;
  const RejectAffiliateRequestEvent(this.requestId, this.reason);
  @override
  List<Object?> get props => [requestId, reason];
}

// Affiliates
class FetchAllAffiliatesEvent extends AffiliateEvent {
  final String? status;
  final String? search;
  const FetchAllAffiliatesEvent({this.status, this.search});
  @override
  List<Object?> get props => [status, search];
}

class UpdateAffiliateEvent extends AffiliateEvent {
  final String affiliateId;
  final double? commissionRate;
  final String? status;
  const UpdateAffiliateEvent(
    this.affiliateId, {
    this.commissionRate,
    this.status,
  });
  @override
  List<Object?> get props => [affiliateId, commissionRate, status];
}

// Promo codes
class FetchAllPromoCodesEvent extends AffiliateEvent {
  final String? type;
  final bool? isActive;
  const FetchAllPromoCodesEvent({this.type, this.isActive});
  @override
  List<Object?> get props => [type, isActive];
}

class CreateSystemPromoCodeEvent extends AffiliateEvent {
  final Map<String, dynamic> data;
  const CreateSystemPromoCodeEvent(this.data);
  @override
  List<Object?> get props => [data];
}

class AdminUpdatePromoCodeEvent extends AffiliateEvent {
  final String promoCodeId;
  final Map<String, dynamic> data;
  const AdminUpdatePromoCodeEvent({
    required this.promoCodeId,
    required this.data,
  });
  @override
  List<Object?> get props => [promoCodeId, data];
}

class AdminDeletePromoCodeEvent extends AffiliateEvent {
  final String promoCodeId;
  const AdminDeletePromoCodeEvent({required this.promoCodeId});
  @override
  List<Object?> get props => [promoCodeId];
}

// Commissions
class FetchAllCommissionsEvent extends AffiliateEvent {
  final String? status;
  final String? affiliateId;
  const FetchAllCommissionsEvent({this.status, this.affiliateId});
  @override
  List<Object?> get props => [status, affiliateId];
}

class PayCommissionsEvent extends AffiliateEvent {
  final List<String> commissionIds;
  final String? paymentNote;
  const PayCommissionsEvent(this.commissionIds, {this.paymentNote});
  @override
  List<Object?> get props => [commissionIds, paymentNote];
}

// ── Affiliate Settings ─────────────────────────────
class FetchAffiliateSettingsEvent extends AffiliateEvent {
  const FetchAffiliateSettingsEvent();
}

class SaveAffiliateSettingsEvent extends AffiliateEvent {
  final Map<String, dynamic> data;
  const SaveAffiliateSettingsEvent(this.data);
  @override
  List<Object?> get props => [data];
}
