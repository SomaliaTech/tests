import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/admin/domain/entities/market_entity.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_state.dart';
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

  /// For single product checkout
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

  /// For cart checkout
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

  final List<PaymentMethod> _paymentMethods = const [
    PaymentMethod(
      id: 'evc_plus',
      name: 'EVC Plus',
      icon: Iconsax.mobile,
      color: Color(0xFF2ED573),
      description: 'Pay with EVC Plus mobile money',
    ),
    // PaymentMethod(
    //   id: 'cash_on_delivery',
    //   name: 'Cash on Delivery',
    //   icon: Iconsax.wallet,
    //   color: Color(0xFFF59E0B),
    //   description: 'Pay when you receive your order',
    // ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    debugPrint('=== CHECKOUT DATA ===');
    debugPrint('Is Cart Checkout: ${widget.isCartCheckout}');
    debugPrint('Available Markets: ${widget.availableMarkets.length}');
    debugPrint('User Market ID: ${widget.userMarketId}');

    if (widget.savedAddress != null) {
      _addressController.text = widget.savedAddress!.fullAddress;
      _phoneController.text = widget.savedAddress!.phoneNumber;
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
      debugPrint('Selected Market: ${_selectedMarket?.name}');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryFillPhoneNumber();
    });

    setState(() {});
  }

  void _tryFillPhoneNumber() {
    if (!mounted) return;
    try {
      final authState = context.read<AuthBloc>().state;
      final phone = _extractPhoneNumber(authState);
      if (phone.isNotEmpty && _phoneController.text.isEmpty) {
        setState(() => _phoneController.text = phone);
      }
    } catch (e) {
      debugPrint('Could not read auth state: $e');
    }
  }

  String _extractPhoneNumber(AuthState state) {
    if (state is Authenticated) return state.user.phoneNumber;
    if (state is OtpVerified) return state.user.phoneNumber;
    if (state is ProfileCompleted) return state.user.phoneNumber;
    return '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
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
  // ✅ Items for API - capped at max stock
  // ✅ Items for API - capped at max stock
  List<Map<String, dynamic>> get _orderItems {
    if (widget.isCartCheckout) {
      return widget.cartItems!
          .where((item) => item.inStock) // Skip out of stock items
          .map((item) {
            // ✅ Cap quantity at max stock
            final safeQuantity = item.quantity > item.maxStock
                ? item.maxStock
                : item.quantity;

            return {
              'productId': item.productId,
              'productVariantId': item.productVariantId,
              'quantity': safeQuantity,
            };
          })
          .toList();
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

  void _processPayment() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMarket == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a market')));
      return;
    }
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    // ✅ Check for stock issues before proceeding
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
    final orderData = {
      'items': _orderItems,
      'shippingAddress': {
        'label': _selectedLabel ?? 'Other',
        'fullAddress': _addressController.text,
        'phoneNumber': _phoneController.text,
      },
      'paymentMethod': _selectedPaymentMethod,
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
                : _phoneController.text;

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
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMarketSection(),
                      const SizedBox(height: 16),
                      _buildAddressSection(),
                      const SizedBox(height: 16),
                      _buildOrderSummary(),
                      const SizedBox(height: 16),
                      _buildPaymentSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildPayButton(),
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
    if (!mounted) return; // ✅ Check mounted before navigation
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentFailedPage(
          errorMessage: message,
          onTryAgain: () {
            if (mounted) Navigator.of(context).pop(); // ✅ Check mounted
          },
        ),
      ),
    );
  }

  Widget _buildMarketSection() {
    return _buildSectionCard(
      icon: Iconsax.buildings,
      iconColor: const Color(0xFF2ED573),
      title: 'Delivery Market',
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MarketEntity>(
              isExpanded: true,
              value: _selectedMarket,
              hint: const Text('Select market'),
              items: widget.availableMarkets.map((market) {
                return DropdownMenuItem(
                  value: market,
                  child: Text(
                    market.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
              onChanged: (MarketEntity? newMarket) {
                if (newMarket != null) {
                  setState(() => _selectedMarket = newMarket);
                }
              },
            ),
          ),
        ),
        if (_selectedMarket != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  icon: Iconsax.clock,
                  label: 'Est. Time',
                  value: '${_selectedMarket!.deliveryEstimationMinutes} min',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoChip(
                  icon: Iconsax.money,
                  label: 'Delivery',
                  value: _deliveryFee == 0.0
                      ? 'FREE'
                      : '\$${_deliveryFee.toStringAsFixed(2)}',
                  color: _deliveryFee == 0.0
                      ? const Color(0xFF2ED573)
                      : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAddressSection() {
    return _buildSectionCard(
      icon: Iconsax.location,
      iconColor: const Color(0xFF2ED573),
      title: 'Delivery Address',
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ED573).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _selectedLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2ED573),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                _addressController.text.isNotEmpty
                    ? _addressController.text
                    : 'No address provided',
                style: TextStyle(
                  fontSize: 14,
                  color: _addressController.text.isNotEmpty
                      ? const Color(0xFF1F2937)
                      : Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              // ✅ Editable Phone Number Field
              const Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Iconsax.call, size: 18),
                  hintText: 'Enter phone number for delivery',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF2ED573),
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.trim().length < 7) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        // ✅ Show payment phone info when EVC Plus is selected
        if (_selectedPaymentMethod == 'evc_plus') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2ED573).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2ED573).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ED573).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Iconsax.mobile,
                    color: Color(0xFF2ED573),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Phone',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2ED573),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'EVC Plus payment will be sent to: ${_phoneController.text.isNotEmpty ? _phoneController.text : "No phone entered"}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOrderSummary() {
    return _buildSectionCard(
      icon: Iconsax.shopping_bag,
      iconColor: const Color(0xFF2ED573),
      title: 'Order Summary',
      children: [
        const SizedBox(height: 12),
        // Show items
        if (widget.isCartCheckout)
          ...widget.cartItems!.map(_buildCartItemRow)
        else if (widget.product != null)
          _buildSingleProductRow(),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        _buildSummaryRow(
          'Items ($_itemCount)',
          '\$${_subtotal.toStringAsFixed(2)}',
        ),
        if (_deliveryFee > 0)
          _buildSummaryRow(
            'Delivery Fee',
            '\$${_deliveryFee.toStringAsFixed(2)}',
          )
        else
          _buildSummaryRow('Delivery', 'FREE', color: const Color(0xFF2ED573)),
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 8),
        _buildSummaryRow(
          'Total',
          '\$${_totalAmount.toStringAsFixed(2)}',
          isTotal: true,
          color: const Color(0xFF2ED573),
        ),
      ],
    );
  }

  Widget _buildSingleProductRow() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: widget.product!.imageUrls.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.product!.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Iconsax.image, color: Color(0xFF9CA3AF)),
                  ),
                )
              : const Icon(Iconsax.box_1, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product!.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.selectedColor != null || widget.selectedSize != null)
                Text(
                  '${widget.selectedColor ?? ''} ${widget.selectedSize ?? ''}'
                      .trim(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${_unitPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              'Qty: ${widget.quantity}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCartItemRow(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: item.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Iconsax.image,
                        color: Color(0xFF9CA3AF),
                        size: 20,
                      ),
                    ),
                  )
                : const Icon(Iconsax.box_1, color: Color(0xFF9CA3AF), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.color ?? ''} ${item.size ?? ''} x${item.quantity}'
                      .trim(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${item.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return _buildSectionCard(
      icon: Iconsax.wallet_2,
      iconColor: Colors.purple,
      title: 'Payment Method',
      children: [
        const SizedBox(height: 12),
        ..._paymentMethods.map((method) {
          final isSelected = _selectedPaymentMethod == method.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedPaymentMethod = method.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          method.color.withValues(alpha: 0.1),
                          method.color.withValues(alpha: 0.05),
                        ],
                      )
                    : null,
                color: isSelected ? null : const Color(0xFFF9FAFB),
                border: Border.all(
                  color: isSelected ? method.color : const Color(0xFFE5E7EB),
                  width: isSelected ? 2 : 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: method.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(method.icon, color: method.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      method.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? method.color
                            : const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: method.color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.tick_circle,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPayButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: const Color(0xFF2ED573).withValues(alpha: 0.4),
              elevation: 8,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _isProcessing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.security_card, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Pay \$${_totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: color ?? const Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: color ?? const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}
