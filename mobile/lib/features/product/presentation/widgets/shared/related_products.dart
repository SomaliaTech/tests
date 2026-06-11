// import 'package:flutter/material.dart';
// import 'package:iconsax/iconsax.dart';
// import 'package:mobile/features/product/domain/entities/product.dart';

// class RelatedProducts extends StatelessWidget {
//   final List<Product> products;
//   final Function(String) onProductTap;

//   const RelatedProducts({
//     super.key,
//     required this.products,
//     required this.onProductTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (products.isEmpty) return const SizedBox.shrink();

//     return Padding(
//       padding: const EdgeInsets.all(10),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 "Related Products",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF333333),
//                 ),
//               ),
//               TextButton(
//                 onPressed: null,
//                 child: Text(
//                   "View All",
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF2ED573),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           // const SizedBox(height: 15),
//           GridView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               crossAxisSpacing: 12,
//               mainAxisSpacing: 15,
//               mainAxisExtent: 250,
//             ),
//             itemCount: products.length,
//             itemBuilder: (context, index) {
//               final product = products[index];
//               return _RelatedProductCard(
//                 product: product,
//                 onTap: () => onProductTap(product.id),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _RelatedProductCard extends StatelessWidget {
//   final Product product;
//   final VoidCallback onTap;

//   const _RelatedProductCard({required this.product, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(4),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey.shade400),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.1),
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             // Product Image Container
//             SizedBox(
//               height: 160,
//               child: ClipRRect(
//                 borderRadius: const BorderRadius.all(Radius.circular(12)),
//                 child: Stack(
//                   children: [
//                     Image.network(
//                       product.image,
//                       height: 160,
//                       width: double.infinity,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) {
//                         return Container(
//                           width: double.infinity,
//                           color: Colors.grey.shade200,
//                           child: const Icon(
//                             Iconsax.image,
//                             size: 40,
//                             color: Colors.grey,
//                           ),
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             // Content Area
//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       product.name,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xFF333333),
//                         height: 1.2,
//                       ),
//                     ),
//                     const Divider(height: 4),
//                     Row(
//                       children: [
//                         Text(
//                           "\$${product.price.toStringAsFixed(2)}",
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xFF2ED573),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
