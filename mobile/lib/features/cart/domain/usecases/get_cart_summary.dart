// import '../entities/cart_item.dart';

// class GetCartSummary {
//   const GetCartSummary();

//   CartSummary call(List<CartItem> items, Coupon? appliedCoupon) {
//     // Convert to double explicitly to avoid type issues
//     final subtotal = items.fold<double>(
//       0.0,
//       (sum, item) => sum + item.totalPrice,
//     );
//     final shippingFee = subtotal > 50 ? 0.0 : 5.0;
//     final discount = appliedCoupon?.calculateDiscount(subtotal) ?? 0.0;
//     final total = subtotal + shippingFee - discount;
//     final itemCount = items.fold<int>(0, (sum, item) => sum + item.quantity);

//     return CartSummary(
//       subtotal: subtotal,
//       shippingFee: shippingFee,
//       discount: discount,
//       total: total,
//       itemCount: itemCount,
//     );
//   }
// }

// class CartSummary {
//   final double subtotal;
//   final double shippingFee;
//   final double discount;
//   final double total;
//   final int itemCount;

//   const CartSummary({
//     required this.subtotal,
//     required this.shippingFee,
//     required this.discount,
//     required this.total,
//     required this.itemCount,
//   });
// }
