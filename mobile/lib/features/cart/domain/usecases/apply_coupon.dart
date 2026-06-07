import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/error/failure.dart';

import '../entities/cart_item.dart';

class ApplyCoupon {
  final Map<String, Coupon> validCoupons;

  ApplyCoupon({required this.validCoupons});

  Either<Failure, Coupon> call(String code) {
    final coupon = validCoupons[code.toUpperCase()];
    if (coupon != null) {
      return Right(coupon);
    }
    return Left(Failure('Invalid coupon code'));
  }
}
