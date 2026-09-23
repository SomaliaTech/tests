import 'package:mobile/features/admin/domain/entities/affiliate_entity.dart';
import 'package:mobile/features/admin/domain/entities/affiliate_request_entity.dart';
import 'package:mobile/features/admin/domain/entities/promo_code_entity.dart';

abstract class AffiliateRepository {
  // Dashboard
  Future<Map<String, dynamic>> getAffiliateDashboard();

  // Requests
  Future<List<AffiliateRequestEntity>> getAffiliateRequests({String? status});
  Future<void> approveAffiliateRequest(
    String requestId, {
    double? commissionRate,
  });
  Future<void> rejectAffiliateRequest(String requestId, String reason);

  // Affiliates
  Future<List<AffiliateEntity>> getAllAffiliates({
    String? status,
    String? search,
  });
  Future<AffiliateEntity> getAffiliateDetail(String affiliateId);
  Future<void> updateAffiliate(
    String affiliateId, {
    double? commissionRate,
    String? status,
  });
  // Settings
  Future<Map<String, dynamic>> getAffiliateSettings();
  Future<Map<String, dynamic>> updateAffiliateSettings(
    Map<String, dynamic> data,
  );
  // Promo codes
  Future<List<PromoCodeEntity>> getAllPromoCodes({
    String? type,
    bool? isActive,
  });
  Future<void> createSystemPromoCode(Map<String, dynamic> data);
  Future<void> updatePromoCodeByAdmin(
    String promoId,
    Map<String, dynamic> data,
  );
  Future<void> deletePromoCodeByAdmin(String promoCodeId);

  // Commissions
  Future<Map<String, dynamic>> getAllCommissions({
    String? status,
    String? affiliateId,
  });
  Future<void> payCommissions(
    List<String> commissionIds, {
    String? paymentNote,
  });
}
