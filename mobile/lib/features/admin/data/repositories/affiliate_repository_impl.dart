import 'package:mobile/features/admin/data/datasources/affiliate_remote_data_source.dart';
import 'package:mobile/features/admin/domain/entities/affiliate_entity.dart';
import 'package:mobile/features/admin/domain/entities/affiliate_request_entity.dart';
import 'package:mobile/features/admin/domain/entities/promo_code_entity.dart';
import 'package:mobile/features/admin/domain/repositories/affiliate_repository.dart';

class AffiliateRepositoryImpl implements AffiliateRepository {
  final AffiliateRemoteDataSource remoteDataSource;

  AffiliateRepositoryImpl({required this.remoteDataSource});

  // ==========================================
  // USER / AFFILIATE METHODS
  // ==========================================

  @override
  Future<Map<String, dynamic>> getMyAffiliateStats() =>
      remoteDataSource.getMyAffiliateStats();

  @override
  Future<List<Map<String, dynamic>>> getMyPromoCodes() =>
      remoteDataSource.getMyPromoCodes();

  @override
  Future<List<Map<String, dynamic>>> getMyCommissions({String? status}) =>
      remoteDataSource.getMyCommissions(status: status);

  @override
  Future<void> createMyPromoCode(Map<String, dynamic> data) =>
      remoteDataSource.createMyPromoCode(data);

  @override
  Future<void> toggleMyPromoCode(String promoCodeId, bool isActive) =>
      remoteDataSource.toggleMyPromoCode(promoCodeId, isActive);

  @override
  Future<void> deleteMyPromoCode(String promoCodeId) =>
      remoteDataSource.deleteMyPromoCode(promoCodeId);

  @override
  Future<void> applyForAffiliate({
    required String businessName,
    String? description,
    String? phoneNumber,
  }) => remoteDataSource.applyForAffiliate(
    businessName: businessName,
    description: description,
    phoneNumber: phoneNumber,
  );

  @override
  Future<Map<String, dynamic>> validatePromoCode(
    String code,
    double orderAmount,
  ) => remoteDataSource.validatePromoCode(code, orderAmount);

  // ==========================================
  // ADMIN METHODS
  // ==========================================

  @override
  Future<Map<String, dynamic>> getAffiliateDashboard() =>
      remoteDataSource.getAffiliateDashboard();

  @override
  Future<List<AffiliateRequestEntity>> getAffiliateRequests({String? status}) =>
      remoteDataSource.getAffiliateRequests(status: status);

  @override
  Future<void> approveAffiliateRequest(
    String requestId, {
    double? commissionRate,
  }) => remoteDataSource.approveAffiliateRequest(
    requestId,
    commissionRate: commissionRate,
  );

  @override
  Future<void> rejectAffiliateRequest(String requestId, String reason) =>
      remoteDataSource.rejectAffiliateRequest(requestId, reason);

  @override
  Future<List<AffiliateEntity>> getAllAffiliates({
    String? status,
    String? search,
  }) => remoteDataSource.getAllAffiliates(status: status, search: search);

  @override
  Future<AffiliateEntity> getAffiliateDetail(String affiliateId) =>
      remoteDataSource.getAffiliateDetail(affiliateId);

  @override
  Future<void> updateAffiliate(
    String affiliateId, {
    double? commissionRate,
    String? status,
  }) async {
    final data = <String, dynamic>{};
    if (commissionRate != null) data['commissionRate'] = commissionRate;
    if (status != null) data['status'] = status;
    await remoteDataSource.updateAffiliate(affiliateId, data);
  }

  @override
  Future<List<PromoCodeEntity>> getAllPromoCodes({
    String? type,
    bool? isActive,
  }) => remoteDataSource.getAllPromoCodes(type: type, isActive: isActive);

  @override
  Future<void> createSystemPromoCode(Map<String, dynamic> data) =>
      remoteDataSource.createSystemPromoCode(data);

  @override
  Future<Map<String, dynamic>> getAffiliateSettings() =>
      remoteDataSource.getAffiliateSettings();

  @override
  Future<Map<String, dynamic>> updateAffiliateSettings(
    Map<String, dynamic> data,
  ) => remoteDataSource.updateAffiliateSettings(data);
  @override
  Future<void> updatePromoCodeByAdmin(
    String promoId,
    Map<String, dynamic> data,
  ) => remoteDataSource.updatePromoCodeByAdmin(promoId, data);

  @override
  Future<void> deletePromoCodeByAdmin(String promoCodeId) =>
      remoteDataSource.deletePromoCodeByAdmin(promoCodeId);

  @override
  Future<Map<String, dynamic>> getAllCommissions({
    String? status,
    String? affiliateId,
  }) => remoteDataSource.getAllCommissions(
    status: status,
    affiliateId: affiliateId,
  );

  @override
  Future<void> payCommissions(
    List<String> commissionIds, {
    String? paymentNote,
  }) =>
      remoteDataSource.payCommissions(commissionIds, paymentNote: paymentNote);
}
