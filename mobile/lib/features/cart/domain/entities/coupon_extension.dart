import 'cart_item.dart';

extension CouponExtension on Coupon {
  double calculateDiscount(double subtotal) {
    switch (type) {
      case CouponType.percentage:
        return (subtotal * discount) / 100;
      case CouponType.fixed:
        return discount;
    }
  }
}
