// import 'package:flutter/material.dart';
// import 'package:iconsax/iconsax.dart';

// class BottomActionBar extends StatelessWidget {
//   final String productName;
//   final bool isInWishlist;
//   final VoidCallback onFavoriteTap;
//   final VoidCallback onBuyNowTap;

//   // 🚨 ADDED: The missing parameter
//   final VoidCallback? onAddToCartTap;

//   const BottomActionBar({
//     super.key,
//     required this.productName,
//     required this.isInWishlist,
//     required this.onFavoriteTap,
//     required this.onBuyNowTap,
//     this.onAddToCartTap, // 🚨 ADDED
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border(
//           top: BorderSide(color: Colors.grey.shade200, width: 0.5),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 20,
//             offset: const Offset(0, -4),
//           ),
//         ],
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           // ==========================================
//           // LEFT: Wishlist Heart Button (Circular)
//           // ==========================================
//           GestureDetector(
//             onTap: onFavoriteTap,
//             child: Container(
//               width: 52,
//               height: 52,
//               decoration: BoxDecoration(
//                 color: isInWishlist ? Colors.red.shade50 : Colors.grey.shade50,
//                 shape: BoxShape.circle,
//                 border: Border.all(
//                   color: isInWishlist
//                       ? Colors.red.shade200
//                       : Colors.grey.shade200,
//                   width: 1.2,
//                 ),
//               ),
//               child: Icon(
//                 isInWishlist ? Iconsax.heart5 : Iconsax.heart,
//                 color: isInWishlist ? Colors.red : Colors.grey.shade600,
//                 size: 22,
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),

//           // ==========================================
//           // RIGHT: Two Stacked Action Buttons
//           // ==========================================
//           Expanded(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Top Button: Add to Cart (Outlined)
//                 SizedBox(
//                   width: double.infinity,
//                   height: 46,
//                   child: ElevatedButton(
//                     // 🚨 WIRED UP HERE
//                     onPressed: onAddToCartTap,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.white,
//                       foregroundColor: const Color(0xFF2ED573),
//                       side: const BorderSide(
//                         color: Color(0xFF2ED573),
//                         width: 1.5,
//                       ),
//                       padding: EdgeInsets.zero,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 0,
//                     ),
//                     child: const Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Iconsax.shopping_cart, size: 18),
//                         SizedBox(width: 8),
//                         Text(
//                           'Add to Cart',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 8),

//                 // Bottom Button: Buy Now (Filled - Primary CTA)
//                 SizedBox(
//                   width: double.infinity,
//                   height: 46,
//                   child: ElevatedButton(
//                     onPressed: onBuyNowTap,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF2ED573),
//                       foregroundColor: Colors.white,
//                       padding: EdgeInsets.zero,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 0,
//                       shadowColor: const Color(0xFF2ED573).withOpacity(0.3),
//                     ),
//                     child: const Text(
//                       'Buy Now',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'chat_button.dart';

class BottomActionBar extends StatelessWidget {
  final String productName;
  final bool isInWishlist;
  final VoidCallback onFavoriteTap;
  final VoidCallback onAddToCartTap;
  final VoidCallback onBuyNowTap;

  const BottomActionBar({
    super.key,
    required this.productName,
    required this.isInWishlist,
    required this.onFavoriteTap,
    required this.onAddToCartTap,
    required this.onBuyNowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Chat with Admin Button
            const ChatWithAdminButton(),
            const SizedBox(width: 8),

            // Favorite Button
            GestureDetector(
              onTap: onFavoriteTap,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isInWishlist
                      ? const Color(0xFFFF4757).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isInWishlist
                        ? const Color(0xFFFF4757)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Icon(
                  isInWishlist ? Iconsax.heart5 : Iconsax.heart,
                  color: isInWishlist
                      ? const Color(0xFFFF4757)
                      : Colors.grey.shade600,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Add to Cart Button
            Expanded(
              child: GestureDetector(
                onTap: onAddToCartTap,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ED573),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.shopping_cart,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Add to Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Buy Now Button
            Expanded(
              child: GestureDetector(
                onTap: onBuyNowTap,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ED573),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.dollar_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Buy Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
