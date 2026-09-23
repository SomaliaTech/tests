import 'package:mobile/features/admin/domain/entities/promo_code_entity.dart';
import 'package:mobile/features/affiliate/data/datasources/affiliate_user_remote_data_source.dart';
import 'package:mobile/features/affiliate/domain/repositories/affiliate_user_repository.dart';

class AffiliateUserRepositoryImpl implements AffiliateUserRepository {
  final AffiliateUserRemoteDataSource remote;

  AffiliateUserRepositoryImpl({required this.remote});

  @override
  Future<void> applyForAffiliate({
    required String businessName,
    String? description,
    String? phoneNumber,
    Map<String, dynamic>? socialMediaLinks,
    int? expectedAudience,
  }) => remote.applyForAffiliate(
    businessName: businessName,
    description: description,
    phoneNumber: phoneNumber,
    socialMediaLinks: socialMediaLinks,
    expectedAudience: expectedAudience,
  );

  @override
  Future<Map<String, dynamic>?> getMyAffiliateProfile() =>
      remote.getMyAffiliateProfile();

  @override
  Future<Map<String, dynamic>> getMyDashboardStats() =>
      remote.getMyDashboardStats();

  @override
  Future<List<PromoCodeEntity>> getMyPromoCodes() => remote.getMyPromoCodes();

  @override
  Future<void> createMyPromoCode(Map<String, dynamic> data) =>
      remote.createMyPromoCode(data);

  @override
  Future<void> toggleMyPromoCode(String promoCodeId, bool isActive) =>
      remote.toggleMyPromoCode(promoCodeId, isActive);

  @override
  Future<void> deleteMyPromoCode(String promoCodeId) =>
      remote.deleteMyPromoCode(promoCodeId);

  @override
  Future<List<Map<String, dynamic>>> getMyCommissions({String? status}) =>
      remote.getMyCommissions(status: status);

  @override
  Future<Map<String, dynamic>> validatePromoCode(
    String code,
    double orderAmount,
  ) => remote.validatePromoCode(code, orderAmount);
}
