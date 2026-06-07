import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'address_selection_modal.dart';

class AddAddressForm extends StatefulWidget {
  final Function(Address) onAddressAdded;

  const AddAddressForm({super.key, required this.onAddressAdded});

  @override
  State<AddAddressForm> createState() => _AddAddressFormState();
}

class _AddAddressFormState extends State<AddAddressForm> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedLabel;
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  String? _selectedCountry;
  bool _isDefault = false;

  final List<String> _labels = ['Home', 'Work', 'Other'];
  final List<String> _countries = ['Somalia', 'Kenya', 'Ethiopia', 'Djibouti'];

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newAddress = Address(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: _selectedLabel ?? 'Other',
        name: _nameController.text,
        street: _streetController.text,
        city: _cityController.text,
        zipCode: _zipController.text,
        country: _selectedCountry ?? 'Somalia',
        isDefault: _isDefault,
      );
      widget.onAddressAdded(newAddress);

      // Clear form
      _nameController.clear();
      _streetController.clear();
      _cityController.clear();
      _zipController.clear();
      setState(() {
        _selectedLabel = null;
        _selectedCountry = null;
        _isDefault = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Iconsax.minus, size: 20),
                  onPressed: () {
                    setState(() {
                      _nameController.clear();
                      _streetController.clear();
                      _cityController.clear();
                      _zipController.clear();
                      _selectedLabel = null;
                      _selectedCountry = null;
                      _isDefault = false;
                    });
                  },
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

            // Address Name
            const Text(
              'Address Name *',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g., Home, Office, Vacation House',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter address name' : null,
            ),
            const SizedBox(height: 16),

            // Street Address
            const Text(
              'Street Address *',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _streetController,
              decoration: InputDecoration(
                hintText: 'Enter your street address',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter street address' : null,
            ),
            const SizedBox(height: 16),

            // City and ZIP Code Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'City *',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          hintText: 'Enter city',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter city' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ZIP Code *',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _zipController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter ZIP code',
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
                            ? 'Please enter ZIP code'
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Country
            const Text(
              'Country *',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCountry,
              hint: const Text('Select country'),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              items: _countries.map((country) {
                return DropdownMenuItem(value: country, child: Text(country));
              }).toList(),
              onChanged: (value) => setState(() => _selectedCountry = value),
              validator: (value) =>
                  value == null ? 'Please select country' : null,
            ),
            const SizedBox(height: 16),

            // Set as Default Address - FIXED overflow issue
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            // Helper text for default address
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 4),
              child: Text(
                'Use this address for future orders',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 16),

            // Add Address Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ED573),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add Address',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
