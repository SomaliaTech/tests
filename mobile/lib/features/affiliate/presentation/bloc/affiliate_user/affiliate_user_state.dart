import 'package:equatable/equatable.dart';
import 'package:mobile/features/admin/domain/entities/promo_code_entity.dart';

abstract class AffiliateUserState extends Equatable {
  const AffiliateUserState();
  @override
  List<Object?> get props => [];
}

class AffiliateUserInitial extends AffiliateUserState {}

class AffiliateUserLoading extends AffiliateUserState {}

// Application submitted successfully
class AffiliateApplicationSubmitted extends AffiliateUserState {
  final String message;
  const AffiliateApplicationSubmitted(this.message);
  @override
  List<Object?> get props => [message];
}

// Profile
class MyAffiliateProfileLoaded extends AffiliateUserState {
  final Map<String, dynamic>? profile;
  const MyAffiliateProfileLoaded(this.profile);
  @override
  List<Object?> get props => [profile];

  /// Helper flags for the UI
  bool get isAffiliate => profile != null && (profile!['isAffiliate'] == true);

  bool get isPending => profile != null && profile!['status'] == 'PENDING';

  bool get isRejected => profile != null && profile!['status'] == 'REJECTED';

  bool get isApproved => profile != null && profile!['status'] == 'APPROVED';

  bool get isNone => profile == null || profile!['status'] == 'NONE';
}

// Promo codes
class MyPromoCodesLoaded extends AffiliateUserState {
  final List<PromoCodeEntity> promoCodes;
  const MyPromoCodesLoaded(this.promoCodes);
  @override
  List<Object?> get props => [promoCodes];
}

// Commissions
class MyCommissionsLoaded extends AffiliateUserState {
  final List<Map<String, dynamic>> commissions;
  const MyCommissionsLoaded(this.commissions);
  @override
  List<Object?> get props => [commissions];
}

// Success feedback
class AffiliateUserOperationSuccess extends AffiliateUserState {
  final String message;
  const AffiliateUserOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// Error
class AffiliateUserError extends AffiliateUserState {
  final String message;
  const AffiliateUserError(this.message);
  @override
  List<Object?> get props => [message];
}

class MyDashboardStatsLoaded extends AffiliateUserState {
  final Map<String, dynamic> stats;
  const MyDashboardStatsLoaded(this.stats);

  /// ✅ True if user is an approved/active affiliate
  bool get isAffiliate =>
      stats['isAffiliate'] == true ||
      stats['uniqueCode'] != null ||
      stats['status'] == 'ACTIVE';

  /// Convenience flags
  bool get isSuspended => stats['status'] == 'SUSPENDED';

  bool get isActive => stats['status'] == 'ACTIVE' && isAffiliate;

  @override
  List<Object?> get props => [stats];
}
