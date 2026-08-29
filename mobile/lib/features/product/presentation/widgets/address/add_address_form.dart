import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/common/widgets/shared/checkout_payment_modal.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mobile/features/product/domain/entities/address.dart';
import 'package:mobile/features/product/presentation/blocs/address_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/address_event.dart';
import 'package:mobile/features/product/presentation/blocs/address_state.dart';
import 'package:mobile/features/admin/domain/entities/market_entity.dart';
import 'package:mobile/features/product/domain/entities/product.dart';
import 'package:mobile/features/cart/domain/entities/cart_item.dart';

class AddAddressForm extends StatefulWidget {
  final Function(Address)? onAddressAdded;
  final bool navigateToCheckout;
  final List<MarketEntity>? availableMarkets;
  final String? userMarketId;
  final Product? product;
  final String? selectedColor;
  final String? selectedSize;
  final int quantity;
  final List<CartItem>? cartItems;

  const AddAddressForm({
    super.key,
    this.onAddressAdded,
    this.navigateToCheckout = false,
    this.availableMarkets,
    this.userMarketId,
    this.product,
    this.selectedColor,
    this.selectedSize,
    this.quantity = 1,
    this.cartItems,
  });

  @override
  State<AddAddressForm> createState() => _AddAddressFormState();
}

class _AddAddressFormState extends State<AddAddressForm> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedLabel;
  final _fullAddressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isDefault = false;
  bool _isSubmitting = false;

  final List<String> _labels = ['Home', 'Work', 'Office', 'Other'];

  @override
  void initState() {
    super.initState();
    _selectedLabel = 'Home';
    _tryFillPhoneNumber();
  }

  void _tryFillPhoneNumber() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final authState = context.read<AuthBloc>().state;
        final phone = _extractPhoneNumber(authState);
        if (phone.isNotEmpty && _phoneController.text.isEmpty) {
          setState(() {
            _phoneController.text = phone;
          });
        }
      } catch (e) {
        debugPrint('Could not read auth state: $e');
      }
    });
  }

  String _extractPhoneNumber(AuthState state) {
    if (state is Authenticated) return state.user.phoneNumber;
    if (state is OtpVerified) return state.user.phoneNumber;
    if (state is ProfileCompleted) return state.user.phoneNumber;
    return '';
  }

  @override
  void dispose() {
    _fullAddressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      setState(() => _isSubmitting = true);

      final newAddress = Address(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: _selectedLabel ?? 'Home',
        fullAddress: _fullAddressController.text,
        phoneNumber: _phoneController.text,
        isDefault: _isDefault,
      );

      print('📦 Submitting address: ${newAddress.toJson()}');

      // Clear form
      _fullAddressController.clear();
      setState(() {
        _selectedLabel = 'Home';
        _isDefault = false;
      });

      // Dispatch to AddressBloc
      context.read<AddressBloc>().add(AddAddressEvent(newAddress));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddressBloc, AddressState>(
      listener: (context, state) {
        if (state is AddressAdded) {
          print('🎯 [AddAddressForm] AddressAdded received');
          print('🎯 navigateToCheckout: ${widget.navigateToCheckout}');
          print('🎯 availableMarkets: ${widget.availableMarkets?.length}');
          print('🎯 product: ${widget.product?.id}');
          print('🎯 cartItems: ${widget.cartItems?.length}');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address added successfully!'),
              backgroundColor: Color(0xFF2ED573),
              duration: Duration(seconds: 1),
            ),
          );

          if (widget.navigateToCheckout) {
            _navigateToCheckoutAfterAddressAdded(state.address);
          } else {
            if (widget.onAddressAdded != null) {
              widget.onAddressAdded!(state.address);
            }
            if (mounted) {
              Navigator.pop(context, state.address);
            }
          }
        } else if (state is AddressError) {
          if (!mounted) return;
          setState(() => _isSubmitting = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        height: _getModalHeight(),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.location_add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Address',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Where should we deliver?',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Iconsax.close_circle,
                      size: 24,
                      color: Color(0xFF6B7280),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            Expanded(child: _buildForm()),
          ],
        ),
      ),
    );
  }

  void _navigateToCheckoutAfterAddressAdded(Address address) {
    print('🚀 [AddAddressForm] Starting navigation to checkout...');

    Widget? checkoutScreen;

    if (widget.cartItems != null && widget.cartItems!.isNotEmpty) {
      print('🛒 Creating CheckoutScreen.fromCart');
      checkoutScreen = CheckoutScreen.fromCart(
        cartItems: widget.cartItems!,
        availableMarkets: widget.availableMarkets!,
        userMarketId: widget.userMarketId,
        savedAddress: address,
      );
    } else if (widget.product != null) {
      print('📦 Creating CheckoutScreen for product');
      checkoutScreen = CheckoutScreen(
        product: widget.product,
        selectedColor: widget.selectedColor,
        selectedSize: widget.selectedSize,
        quantity: widget.quantity,
        availableMarkets: widget.availableMarkets!,
        userMarketId: widget.userMarketId,
        savedAddress: address,
      );
    }

    if (checkoutScreen == null) {
      print('❌ Could not create checkout screen');
      if (widget.onAddressAdded != null) {
        widget.onAddressAdded!(address);
      }
      if (mounted) {
        Navigator.pop(context, address);
      }
      return;
    }

    print('✅ Checkout screen created, navigating...');

    // Use pushAndRemoveUntil to clear all modals and navigate to checkout
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => checkoutScreen!),
      (route) => route.isFirst,
    );
  }

  double _getModalHeight() {
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    final isSmallScreen = screenHeight < 700;
    final availableHeight = screenHeight - padding.top - padding.bottom;
    return isSmallScreen ? availableHeight * 0.95 : screenHeight * 0.85;
  }

  Widget _buildForm() {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final padding = MediaQuery.of(context).padding;
    final bottomPadding = padding.bottom > 0 ? padding.bottom + 16 : 32.0;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: viewInsets.bottom > 0 ? viewInsets.bottom + 20 : bottomPadding,
      ),
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Address Label',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _labels.map((label) {
                  final isSelected = _selectedLabel == label;
                  return GestureDetector(
                    onTap: _isSubmitting
                        ? null
                        : () => setState(
                            () => _selectedLabel = isSelected ? null : label,
                          ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2ED573).withAlpha(77),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF374151),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _buildInputField(
                controller: _fullAddressController,
                label: 'Full Address',
                hint: "Fadlan geli goobta lagugu keenayo alaabta",
                icon: Iconsax.location,
                iconColor: const Color(0xFF3B82F6),
                maxLines: 3,
                enabled: !_isSubmitting,
                validator: (value) => value?.isEmpty ?? true
                    ? 'Fadlan geli meesha alaabta lagugu keenayo.'
                    : null,
              ),
              const SizedBox(height: 20),
              _buildPhoneField(),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _isSubmitting
                    ? null
                    : () => setState(() => _isDefault = !_isDefault),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isDefault
                        ? const Color(0xFF2ED573).withAlpha(13)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isDefault
                          ? const Color(0xFF2ED573)
                          : const Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _isDefault
                              ? const Color(0xFF2ED573)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _isDefault
                                ? const Color(0xFF2ED573)
                                : const Color(0xFFD1D5DB),
                            width: 2,
                          ),
                        ),
                        child: _isDefault
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set as Default Address',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Use this address for future orders',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: const Color(0xFF2ED573).withAlpha(102),
                    elevation: 8,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Ink(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.tick_circle, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Add Address',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: bottomPadding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final phoneNumber = _extractPhoneNumber(authState);
        if (phoneNumber.isNotEmpty && _phoneController.text != phoneNumber) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _phoneController.text != phoneNumber) {
              _phoneController.text = phoneNumber;
            }
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: phoneNumber.isNotEmpty
                    ? const Color(0xFF2ED573).withAlpha(13)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: phoneNumber.isNotEmpty
                      ? const Color(0xFF2ED573)
                      : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Iconsax.call,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      readOnly: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: phoneNumber.isEmpty
                            ? 'Login to auto-fill'
                            : 'Auto-filled from profile',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        color: phoneNumber.isNotEmpty
                            ? const Color(0xFF1F2937)
                            : const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (phoneNumber.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ED573).withAlpha(38),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.verify,
                            size: 12,
                            color: Color(0xFF2ED573),
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF2ED573),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: maxLines > 1 ? 8 : 4,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  maxLines: maxLines,
                  enabled: enabled,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w500,
                  ),
                  validator: validator,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
