import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_event.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_state.dart';
import 'package:mobile/features/product/domain/entities/product.dart';
// 🚨 ADDED: Import CartItem entity
import 'package:mobile/features/cart/domain/entities/cart_item.dart';
import 'package:toastification/toastification.dart';
import 'package:iconsax/iconsax.dart';

class AddToCartButton extends StatefulWidget {
  final Product product;
  final String? selectedColor;
  final String? selectedSize;
  final int quantity;

  const AddToCartButton({
    super.key,
    required this.product,
    this.selectedColor,
    this.selectedSize,
    this.quantity = 1,
  });

  @override
  State<AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<AddToCartButton> {
  bool _isAdding = false;

  ProductVariant? get _selectedVariant {
    if (widget.product.variants.isEmpty) return null;
    try {
      return widget.product.variants.firstWhere(
        (v) =>
            v.colorName == widget.selectedColor &&
            v.sizeName == widget.selectedSize,
        orElse: () => widget.product.variants.first,
      );
    } catch (_) {
      return widget.product.variants.first;
    }
  }

  void _handleAddToCart() async {
    final variant = _selectedVariant;
    if (variant == null) {
      toastification.show(
        title: const Text('Error'),
        description: const Text('Product has no available variants'),
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        autoCloseDuration: const Duration(seconds: 2),
      );
      return;
    }

    setState(() => _isAdding = true);

    // 🚨 FIXED: Construct the full CartItem object locally
    final cartItem = CartItem(
      id: variant.id, // Use variant ID as the unique cart item ID
      productId: widget.product.id,
      productVariantId: variant.id,
      name: widget.product.name,
      imageUrl: widget.product.imageUrls.isNotEmpty
          ? widget.product.imageUrls.first
          : '',
      price: variant.price,
      quantity: widget.quantity,
      maxStock: variant.stock,
      inStock: variant.stock > 0,
      color: variant.colorName,
      size: variant.sizeName,
    );

    final cartBloc = context.read<CartBloc>();
    // 🚨 FIXED: Pass the CartItem object instead of ID/quantity
    cartBloc.add(AddToCartEvent(cartItem));

    // Wait for the state to update
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isAdding = false);
      toastification.show(
        title: const Text('Added to Cart'),
        description: Text('${widget.product.name} added to cart'),
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartError && mounted) {
          setState(() => _isAdding = false);
          toastification.show(
            title: const Text('Error'),
            description: Text(state.message),
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      },
      child: ElevatedButton(
        onPressed: _isAdding ? null : _handleAddToCart,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2ED573),
          foregroundColor: Colors.white,
          minimumSize: const Size(120, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isAdding
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.shopping_cart, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Add to Cart',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}
