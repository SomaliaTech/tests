import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/wishlist/presentation/bloc/wishlist_state.dart';
import 'package:mobile/features/wishlist/presentation/widgets/wishlist_item_card.dart';
import 'package:toastification/toastification.dart';

// Cart imports
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../cart/domain/entities/cart_item.dart';

// Product imports
import '../../../product/presentation/blocs/product_bloc.dart';
import '../../../product/presentation/blocs/product_event.dart';
import '../../../product/presentation/blocs/product_state.dart';

import '../bloc/wishlist_bloc.dart';
import '../bloc/wishlist_event.dart';

class WishlistListView extends StatelessWidget {
  const WishlistListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listener: (context, cartState) {
        if (cartState is CartLoaded) {
          toastification.show(
            title: const Text('Added to Cart'),
            description: const Text('Item successfully added to your cart'),
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            autoCloseDuration: const Duration(seconds: 2),
          );
        } else if (cartState is CartError) {
          toastification.show(
            title: const Text('Error'),
            description: Text(cartState.message),
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      },
      child: BlocBuilder<WishlistBloc, WishlistState>(
        builder: (context, state) {
          if (state is WishlistLoaded) {
            if (state.items.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return _buildDismissibleItem(context, item);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ✅ Empty state widget extracted
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.heart, size: 48, color: Colors.red.shade300),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your wishlist is empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save your favorite items to buy them later',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Dismissible item widget extracted
  Widget _buildDismissibleItem(BuildContext context, dynamic item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Iconsax.trash, color: Colors.white, size: 24),
      ),
      onDismissed: (direction) {
        context.read<WishlistBloc>().add(RemoveFromWishlistEvent(item.id));
        toastification.show(
          title: const Text('Removed'),
          description: Text('${item.name} removed from wishlist'),
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 2),
        );
      },
      child: WishlistItemCard(
        item: item,
        onRemove: () => _handleRemoveItem(context, item),
        onAddToCart: () =>
            _handleAddToCart(context, item), // ✅ Extracted method
      ),
    );
  }

  // ✅ Remove item logic extracted
  void _handleRemoveItem(BuildContext context, dynamic item) {
    context.read<WishlistBloc>().add(RemoveFromWishlistEvent(item.id));
    toastification.show(
      title: const Text('Removed'),
      description: Text('${item.name} removed from wishlist'),
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  // ✅ Add to cart logic extracted
  Future<void> _handleAddToCart(BuildContext context, dynamic item) async {
    if (item.productVariantId.isEmpty) {
      HapticFeedback.heavyImpact();
      toastification.show(
        context: context,
        title: const Text('Cannot Add to Cart'),
        description: const Text(
          'Please select a color and size for this product first',
        ),
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    HapticFeedback.lightImpact();

    try {
      // Fetch real product data to get accurate stock
      final productBloc = context.read<ProductBloc>();
      productBloc.add(GetProductByIdEvent(item.id));

      // Wait a bit for the product to load
      await Future.delayed(const Duration(milliseconds: 500));

      final productState = productBloc.state;
      int maxStock = 999;
      bool inStock = true;

      if (productState is ProductDetailLoaded) {
        final product = productState.product;
        final variant = product.variants.firstWhere(
          (v) => v.id == item.productVariantId,
          orElse: () => product.variants.first,
        );
        maxStock = variant.stock;
        inStock = variant.stock > 0;
      }

      final cartItem = CartItem(
        id: item.productVariantId,
        productId: item.id,
        productVariantId: item.productVariantId,
        name: item.name,
        imageUrl: item.imageUrl ?? '',
        price: item.price,
        quantity: 1,
        maxStock: maxStock,
        inStock: inStock,
        color: null,
        size: null,
      );

      if (context.mounted) {
        context.read<CartBloc>().add(AddToCartEvent(cartItem));
      }
    } catch (e) {
      // Fallback to default values if fetch fails
      final cartItem = CartItem(
        id: item.productVariantId,
        productId: item.id,
        productVariantId: item.productVariantId,
        name: item.name,
        imageUrl: item.imageUrl ?? '',
        price: item.price,
        quantity: 1,
        maxStock: 999,
        inStock: true,
        color: null,
        size: null,
      );

      if (context.mounted) {
        context.read<CartBloc>().add(AddToCartEvent(cartItem));
      }
    }
  }
}
