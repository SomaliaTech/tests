import 'package:equatable/equatable.dart';

abstract class AffiliateUserEvent extends Equatable {
  const AffiliateUserEvent();
  @override
  List<Object?> get props => [];
}

// -----------------------------------------------------------------
// Application
// -----------------------------------------------------------------
class ApplyAffiliateEvent extends AffiliateUserEvent {
  final String businessName;
  final String? description;
  final String? phoneNumber;
  final Map<String, dynamic>? socialMediaLinks;
  final int? expectedAudience;

  const ApplyAffiliateEvent({
    required this.businessName,
    this.description,
    this.phoneNumber,
    this.socialMediaLinks,
    this.expectedAudience,
  });

  @override
  List<Object?> get props => [
    businessName,
    description,
    phoneNumber,
    socialMediaLinks,
    expectedAudience,
  ];
}

class FetchMyAffiliateProfileEvent extends AffiliateUserEvent {
  const FetchMyAffiliateProfileEvent();
}

// -----------------------------------------------------------------
// Dashboard / stats
// -----------------------------------------------------------------
class FetchMyDashboardStatsEvent extends AffiliateUserEvent {
  const FetchMyDashboardStatsEvent();
}

// -----------------------------------------------------------------
// Promo codes
// -----------------------------------------------------------------
class FetchMyPromoCodesEvent extends AffiliateUserEvent {
  const FetchMyPromoCodesEvent();
}

class CreateMyPromoCodeEvent extends AffiliateUserEvent {
  final Map<String, dynamic> data;
  const CreateMyPromoCodeEvent({required this.data});
  @override
  List<Object?> get props => [data];
}

class ToggleMyPromoCodeEvent extends AffiliateUserEvent {
  final String promoCodeId;
  final bool isActive;
  const ToggleMyPromoCodeEvent({
    required this.promoCodeId,
    required this.isActive,
  });
  @override
  List<Object?> get props => [promoCodeId, isActive];
}

class DeleteMyPromoCodeEvent extends AffiliateUserEvent {
  final String promoCodeId;
  const DeleteMyPromoCodeEvent({required this.promoCodeId});
  @override
  List<Object?> get props => [promoCodeId];
}

// -----------------------------------------------------------------
// Commissions
// -----------------------------------------------------------------
class FetchMyCommissionsEvent extends AffiliateUserEvent {
  final String? status;
  const FetchMyCommissionsEvent({this.status});
  @override
  List<Object?> get props => [status];
}
