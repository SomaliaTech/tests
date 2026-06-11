import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/auth_state.dart';

import 'package:mobile/features/product/domain/entities/address.dart';

class AddAddressForm extends StatefulWidget {
  final Function(Address) onAddressAdded;

  const AddAddressForm({super.key, required this.onAddressAdded});

  @override
  State<AddAddressForm> createState() => _AddAddressFormState();
}

class _AddAddressFormState extends State<AddAddressForm> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedLabel;
  final _fullAddressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isDefault = false;

  final List<String> _labels = ['Home', 'Work', 'Office', 'Other'];

  @override
  void initState() {
    super.initState();
    // 1. Auto-fill phone number from AuthBloc when widget loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        // Set the text only if the controller is empty to avoid overwriting user edits
        if (_phoneController.text.isEmpty) {
          _phoneController.text = authState.user.phoneNumber;
        }
      }
    });
  }

  @override
  void dispose() {
    _fullAddressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newAddress = Address(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: _selectedLabel ?? 'Other',
        fullAddress: _fullAddressController.text,
        phoneNumber: _phoneController.text,
        isDefault: _isDefault,
      );
      widget.onAddressAdded(newAddress);

      // Clear form
      _fullAddressController.clear();
      _phoneController.clear();
      setState(() {
        _selectedLabel = null;
        _isDefault = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address added successfully'),
          backgroundColor: Color(0xFF2ED573),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen height for the 60% modal effect
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 5),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add New Address',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Iconsax.close_circle, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Address Label
                    const Text(
                      'Address Label',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: _labels.map((label) {
                        return ChoiceChip(
                          label: Text(label),
                          showCheckmark: false,
                          selected: _selectedLabel == label,
                          onSelected: (selected) {
                            setState(() {
                              _selectedLabel = selected ? label : null;
                            });
                          },
                          selectedColor: const Color(0xFF2ED573),
                          labelStyle: TextStyle(
                            color: _selectedLabel == label
                                ? Colors.white
                                : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Full Address
                    const Text(
                      'Full Address *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fullAddressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter your full address',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter your full address'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Phone Number (Auto-filled)
                    const Text(
                      'Phone Number *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Enter your phone number',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Iconsax.call, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter your phone number'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Set as Default Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: Checkbox(
                            value: _isDefault,
                            onChanged: (value) =>
                                setState(() => _isDefault = value ?? false),
                            activeColor: const Color(0xFF2ED573),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Set as Default Address',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.only(left: 40, top: 4),
                      child: Text(
                        'Use this address for future orders',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Add Address Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ED573),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Add Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
