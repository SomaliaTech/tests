import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_event.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_state.dart';
import 'package:mobile/features/product/domain/entities/product.dart';
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

  String get _variantId {
    if (widget.product.variants.isEmpty) return '';
    try {
      final variant = widget.product.variants.firstWhere(
        (v) =>
            v.colorName == widget.selectedColor &&
            v.sizeName == widget.selectedSize,
        orElse: () => widget.product.variants.first,
      );
      return variant.id;
    } catch (_) {
      return widget.product.variants.first.id;
    }
  }

  void _handleAddToCart() async {
    if (_variantId.isEmpty) {
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

    final cartBloc = context.read<CartBloc>();
    // FIXED: Use widget.product, not item
    cartBloc.add(
      AddToCartEvent(
        productVariantId: _variantId, // Use _variantId here
        quantity: widget.quantity,
      ),
    );

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
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
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
