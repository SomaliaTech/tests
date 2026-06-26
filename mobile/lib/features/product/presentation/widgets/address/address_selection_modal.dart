import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/product/domain/entities/address.dart';
import 'package:mobile/features/product/presentation/blocs/address_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/address_event.dart';
import 'package:mobile/features/product/presentation/blocs/address_state.dart';
import '../../../../../core/services/injection_container.dart';
import 'add_address_form.dart';

class AddressSelectionModal extends StatefulWidget {
  final Function(Address) onAddressSelected;

  const AddressSelectionModal({super.key, required this.onAddressSelected});

  @override
  State<AddressSelectionModal> createState() => _AddressSelectionModalState();
}

class _AddressSelectionModalState extends State<AddressSelectionModal> {
  late AddressBloc _addressBloc;

  @override
  void initState() {
    super.initState();
    _addressBloc = sl<AddressBloc>()..add(LoadAddressesEvent());
  }

  // ✅ Helper: Close modal first, then notify parent on next frame
  void _selectAddressAndClose(Address address) {
    // 1. Close this modal FIRST
    Navigator.pop(context);

    // 2. Notify parent AFTER the modal is gone
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onAddressSelected(address);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _addressBloc,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildAddressList()),
            _buildAddButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Select Delivery Address',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Iconsax.close_circle),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList() {
    return BlocConsumer<AddressBloc, AddressState>(
      listener: (context, state) {
        // ✅ FIX: When new address is added, close modal first, then notify parent
        if (state is AddressAdded) {
          _selectAddressAndClose(state.address);
        }
      },
      builder: (context, state) {
        if (state is AddressLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2ED573)),
          );
        } else if (state is AddressesLoaded) {
          final addresses = state.addresses;
          if (addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.location, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No addresses saved',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add your first address below',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _buildAddressCard(address);
            },
          );
        } else if (state is AddressError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.warning_2, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAddressCard(Address address) {
    return GestureDetector(
      // ✅ FIX: Use helper method for consistent behavior
      onTap: () => _selectAddressAndClose(address),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: address.isDefault
                ? const Color(0xFF2ED573)
                : const Color(0xFFEEEEEE),
            width: address.isDefault ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: address.isDefault
              ? const Color(0xFF2ED573).withValues(alpha: 0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2ED573).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                address.label == 'Home'
                    ? Iconsax.home
                    : address.label == 'Work'
                    ? Iconsax.building
                    : Iconsax.location,
                color: const Color(0xFF2ED573),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2ED573,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF2ED573),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.fullAddress,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.phoneNumber,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(
              Iconsax.arrow_right_2,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: ElevatedButton.icon(
        onPressed: _showAddAddressForm,
        icon: const Icon(Iconsax.add_circle, size: 20),
        label: const Text(
          'Add New Address',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2ED573),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF2ED573), width: 2),
          ),
        ),
      ),
    );
  }

  void _showAddAddressForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAddressForm(
        onAddressAdded: (newAddress) {
          // Just dispatch event - the BlocConsumer listener handles the rest
          _addressBloc.add(AddAddressEvent(newAddress));
          Navigator.pop(context); // Close the form modal
        },
      ),
    );
  }
}
