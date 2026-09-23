import 'package:mobile/features/admin/domain/entities/affiliate_entity.dart';
import 'package:mobile/features/admin/domain/entities/promo_code_entity.dart';

abstract class AffiliateUserRepository {
  /// Apply to become an affiliate
  Future<void> applyForAffiliate({
    required String businessName,
    String? description,
    String? phoneNumber,
    Map<String, dynamic>? socialMediaLinks,
    int? expectedAudience,
  });

  /// Get my own affiliate profile (null if not an affiliate yet)
  Future<Map<String, dynamic>?> getMyAffiliateProfile();

  /// Dashboard stats for the logged-in affiliate
  Future<Map<String, dynamic>> getMyDashboardStats();

  /// Promo codes owned by me
  Future<List<PromoCodeEntity>> getMyPromoCodes();

  /// Create a new promo code
  Future<void> createMyPromoCode(Map<String, dynamic> data);

  /// Toggle active state
  Future<void> toggleMyPromoCode(String promoCodeId, bool isActive);

  /// Delete my promo code
  Future<void> deleteMyPromoCode(String promoCodeId);

  /// My commission list
  Future<List<Map<String, dynamic>>> getMyCommissions({String? status});

  /// Validate a code during checkout (used by any user)
  Future<Map<String, dynamic>> validatePromoCode(
    String code,
    double orderAmount,
  );
}
