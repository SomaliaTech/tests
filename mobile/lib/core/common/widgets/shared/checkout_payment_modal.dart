// lib/features/product/presentation/screens/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/common/widgets/checkout_address_section.dart';
import 'package:mobile/core/common/widgets/checkout_market_section.dart';
import 'package:mobile/core/common/widgets/checkout_order_summary.dart';
import 'package:mobile/core/common/widgets/checkout_pay_button.dart';
import 'package:mobile/core/common/widgets/checkout_payment_section.dart';
import 'package:mobile/core/common/widgets/shared/payment_method.dart';
import 'package:mobile/core/common/widgets/shared/phone_utils.dart';
import 'package:mobile/features/admin/domain/entities/market_entity.dart';
import 'package:mobile/features/cart/domain/entities/cart_item.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:mobile/features/cart/presentation/bloc/cart_event.dart';
import 'package:mobile/features/order/presentation/bloc/order_bloc.dart';
import 'package:mobile/features/order/presentation/bloc/order_event.dart';
import 'package:mobile/features/order/presentation/bloc/order_state.dart';
import 'package:mobile/features/product/domain/entities/address.dart';
import 'package:mobile/features/product/domain/entities/product.dart';

import 'package:mobile/features/product/presentation/screens/payment_failed_page.dart';
import 'package:mobile/features/product/presentation/screens/payment_success_page.dart';

/// Unified checkout screen that works for both:
/// 1. Single product checkout (Buy Now)
/// 2. Cart checkout (multiple items)
class CheckoutScreen extends StatefulWidget {
  // Single product fields
  final Product? product;
  final String? selectedColor;
  final String? selectedSize;
  final int quantity;

  // Cart fields
  final List<CartItem>? cartItems;

  // Shared fields
  final List<MarketEntity> availableMarkets;
  final String? userMarketId;
  final Address? savedAddress;

  const CheckoutScreen({
    super.key,
    this.product,
    this.selectedColor,
    this.selectedSize,
    this.quantity = 1,
    this.cartItems,
    required this.availableMarkets,
    this.userMarketId,
    this.savedAddress,
  }) : assert(
         product != null || cartItems != null,
         'Either product or cartItems must be provided',
       );

  const CheckoutScreen.fromCart({
    super.key,
    required this.cartItems,
    required this.availableMarkets,
    this.userMarketId,
    this.savedAddress,
  }) : product = null,
       selectedColor = null,
       selectedSize = null,
       quantity = 1;

  bool get isCartCheckout => cartItems != null;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedLabel;

  MarketEntity? _selectedMarket;
  bool _isProcessing = false;
  String? _selectedPaymentMethod = 'evc_plus';
  String? _createdOrderId;

  // ✅ Payment methods
  final List<PaymentMethod> _paymentMethods = PaymentMethod.methods;

  // In checkout_screen.dart, update the GlobalKey type

  // ✅ Use the public state type (no underscore)
  final GlobalKey<CheckoutAddressSectionState> _addressSectionKey =
      GlobalKey<CheckoutAddressSectionState>();

  // ✅ Scroll controller for scrolling to error
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.savedAddress != null) {
      _addressController.text = widget.savedAddress!.fullAddress;
      _phoneController.text = PhoneUtils.getDisplayPhone(
        widget.savedAddress!.phoneNumber,
      );
      _selectedLabel = widget.savedAddress!.label;
    } else {
      _selectedLabel = 'Work';
    }
    if (widget.availableMarkets.isNotEmpty) {
      if (widget.userMarketId != null) {
        _selectedMarket = widget.availableMarkets.firstWhere(
          (m) => m.id == widget.userMarketId,
          orElse: () => widget.availableMarkets.first,
        );
      } else {
        _selectedMarket = widget.availableMarkets.first;
      }
    }

    // Auto-detect provider from phone
    _autoDetectProvider();
  }

  void _autoDetectProvider() {
    final phone = _phoneController.text;
    if (phone.isNotEmpty) {
      final detectedId = PhoneUtils.detectProvider(phone, _paymentMethods);
      if (detectedId != null) {
        setState(() {
          _selectedPaymentMethod = detectedId;
        });
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ Item count
  int get _itemCount {
    if (widget.isCartCheckout) {
      return widget.cartItems!.fold(0, (sum, item) => sum + item.quantity);
    }
    return widget.quantity;
  }

  // ✅ Subtotal
  double get _subtotal {
    if (widget.isCartCheckout) {
      return widget.cartItems!.fold(0.0, (sum, item) => sum + item.totalPrice);
    }
    return _unitPrice * widget.quantity;
  }

  // ✅ Unit price (single product only)
  double get _unitPrice {
    if (widget.isCartCheckout || widget.product == null) return 0;
    final variantPrice = _selectedVariant?.price;
    return (variantPrice != null && variantPrice > 0)
        ? variantPrice
        : widget.product!.price;
  }

  // ✅ Selected variant (single product only)
  ProductVariant? get _selectedVariant {
    if (widget.isCartCheckout || widget.product == null) return null;
    if (widget.product!.variants.isEmpty) return null;
    if (widget.selectedColor == null && widget.selectedSize == null) {
      return widget.product!.variants.first;
    }
    return widget.product!.variants.firstWhere((v) {
      final colorMatch =
          widget.selectedColor == null || v.colorName == widget.selectedColor;
      final sizeMatch =
          widget.selectedSize == null || v.sizeName == widget.selectedSize;
      return colorMatch && sizeMatch;
    }, orElse: () => widget.product!.variants.first);
  }

  // ✅ Delivery fee
  double get _deliveryFee {
    if (_selectedMarket == null) return 0.0;
    final minQty = _selectedMarket!.freeDeliveryMinQuantity;
    if (minQty != null && minQty > 0 && _itemCount >= minQty) {
      return 0.0;
    }
    return _selectedMarket!.deliveryPrice;
  }

  // ✅ Total
  double get _totalAmount => _subtotal + _deliveryFee;

  // ✅ Items for API
  List<Map<String, dynamic>> get _orderItems {
    if (widget.isCartCheckout) {
      return widget.cartItems!.where((item) => item.inStock).map((item) {
        final safeQuantity = item.quantity > item.maxStock
            ? item.maxStock
            : item.quantity;
        return {
          'productId': item.productId,
          'productVariantId': item.productVariantId,
          'quantity': safeQuantity,
        };
      }).toList();
    }
    return [
      {
        'productId': widget.product!.id,
        if (_selectedVariant?.id != null)
          'productVariantId': _selectedVariant!.id,
        'quantity': widget.quantity,
      },
    ];
  }

  // ✅ Scroll to address section when there's an error
  void _scrollToAddressSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // ✅ Updated _processPayment - validates phone and shows error in UI
  void _processPayment() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMarket == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fadlan dooro suuq')));
      return;
    }

    // ✅ Validate phone number
    final phone = _phoneController.text.trim();
    final cleanPhone = PhoneUtils.cleanPhoneNumber(phone);

    // Check if phone is empty or has less than 7 digits
    if (phone.isEmpty || cleanPhone.length < 7) {
      // ✅ Show error in the UI below the input field
      final errorMessage = phone.isEmpty
          ? 'Fadlan geli lambarka taleefanka'
          : 'Lambarka taleefanka waa inuu ka kooban yahay ugu yaraan 7 lambar (waxaad haysaa ${cleanPhone.length})';

      // Call the showError method on the AddressSection
      _addressSectionKey.currentState?.showError(errorMessage);

      // Scroll to the error
      _scrollToAddressSection();
      return;
    }

    // Check if phone matches the selected provider
    if (_selectedPaymentMethod != null) {
      try {
        final method = _paymentMethods.firstWhere(
          (m) => m.id == _selectedPaymentMethod,
        );
        final isValid = PhoneUtils.matchesProvider(
          _phoneController.text,
          method.prefix,
        );
        if (!isValid) {
          // ✅ Show error in the UI below the input field
          final errorMessage = 'Waa inuu ku bilaabmaa +252 ${method.prefix}';
          _addressSectionKey.currentState?.showError(errorMessage);
          _scrollToAddressSection();
          return;
        }
      } catch (e) {
        // Method not found, proceed with caution
      }
    }

    // Clear any existing errors
    _addressSectionKey.currentState?.clearError();

    // Check for stock issues
    if (widget.isCartCheckout) {
      final problemItems = widget.cartItems!
          .where((item) => !item.inStock || item.quantity > item.maxStock)
          .toList();

      if (problemItems.isNotEmpty) {
        final message = StringBuffer('Some items have stock issues:\n\n');
        for (final item in problemItems) {
          if (!item.inStock) {
            message.writeln('• ${item.name}: Out of stock - will be removed');
          } else {
            message.writeln(
              '• ${item.name}: ${item.quantity} → ${item.maxStock} (max stock)',
            );
          }
        }
        message.writeln('\nContinue with adjusted quantities?');

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Stock Warning'),
            content: Text(message.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _executePayment();
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2ED573),
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
        return;
      }
    }

    _executePayment();
  }

  void _executePayment() {
    setState(() => _isProcessing = true);

    final formattedPhone = PhoneUtils.formatPhoneForApi(_phoneController.text);

    final orderData = {
      'items': _orderItems,
      'shippingAddress': {
        'label': _selectedLabel ?? 'Other',
        'fullAddress': _addressController.text,
        'phoneNumber': formattedPhone,
      },
      'paymentMethod': _selectedPaymentMethod,
      'deliveryFee': _deliveryFee,
    };
    context.read<OrderBloc>().add(CreateOrderEvent(orderData));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderCreated) {
            _createdOrderId = state.order.id;
            final phoneNumber = _selectedPaymentMethod == 'cash_on_delivery'
                ? null
                : PhoneUtils.formatPhoneForApi(_phoneController.text);

            context.read<OrderBloc>().add(
              ProcessPaymentEvent(
                orderId: state.order.id,
                paymentMethod: _selectedPaymentMethod!,
                phoneNumber: phoneNumber,
              ),
            );
          } else if (state is PaymentProcessed) {
            setState(() => _isProcessing = false);
            if (widget.isCartCheckout && mounted) {
              context.read<CartBloc>().add(ClearCartEvent());
            }
            _navigateToSuccess(_createdOrderId ?? 'N/A');
          } else if (state is OrderError) {
            setState(() => _isProcessing = false);
            _navigateToFailed(state.message);
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Market Section
                      CheckoutMarketSection(
                        availableMarkets: widget.availableMarkets,
                        selectedMarket: _selectedMarket,
                        onMarketChanged: (market) {
                          setState(() => _selectedMarket = market);
                        },
                        deliveryFee: _deliveryFee,
                        itemCount: _itemCount,
                      ),
                      const SizedBox(height: 16),

                      // Address Section with GlobalKey
                      CheckoutAddressSection(
                        key: _addressSectionKey,
                        selectedLabel: _selectedLabel,
                        addressController: _addressController,
                        phoneController: _phoneController,
                        selectedPaymentMethod: _selectedPaymentMethod,
                        paymentMethods: _paymentMethods,
                        onPhoneChanged: (phone) {
                          // Clear error when user types
                          _addressSectionKey.currentState?.clearError();
                          _autoDetectProvider();
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),

                      // Order Summary
                      CheckoutOrderSummary(
                        isCartCheckout: widget.isCartCheckout,
                        cartItems: widget.cartItems,
                        product: widget.product,
                        selectedColor: widget.selectedColor,
                        selectedSize: widget.selectedSize,
                        quantity: widget.quantity,
                        unitPrice: _unitPrice,
                        itemCount: _itemCount,
                        subtotal: _subtotal,
                        deliveryFee: _deliveryFee,
                        totalAmount: _totalAmount,
                      ),
                      const SizedBox(height: 16),

                      // Payment Section
                      CheckoutPaymentSection(
                        selectedPaymentMethod: _selectedPaymentMethod,
                        onPaymentMethodChanged: (methodId) {
                          setState(() {
                            _selectedPaymentMethod = methodId;
                            // Clear error when payment method changes
                            _addressSectionKey.currentState?.clearError();
                          });
                        },
                        paymentMethods: _paymentMethods,
                        phoneController: _phoneController,
                        onPhoneChanged: (phone) {
                          _addressSectionKey.currentState?.clearError();
                          _autoDetectProvider();
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Pay Button
              CheckoutPayButton(
                onPressed: _processPayment,
                isProcessing: _isProcessing,
                totalAmount: _totalAmount,
                phoneController: _phoneController,
                selectedPaymentMethod: _selectedPaymentMethod,
                paymentMethods: _paymentMethods,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSuccess(String orderId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentSuccessPage(
          orderId: orderId,
          totalAmount: _totalAmount,
          productName: widget.isCartCheckout
              ? '${_itemCount} items'
              : widget.product?.name ?? 'Order',
          productImage: widget.isCartCheckout
              ? null
              : (widget.product?.imageUrls.isNotEmpty == true
                    ? widget.product!.imageUrls.first
                    : null),
          itemCount: widget.isCartCheckout ? _itemCount : null,
        ),
      ),
    );
  }

  void _navigateToFailed(String message) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentFailedPage(
          errorMessage: message,
          onTryAgain: () {
            if (mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
