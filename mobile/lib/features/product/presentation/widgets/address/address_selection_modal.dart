import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'add_address_form.dart';

class Address {
  final String id;
  final String label;
  final String name;
  final String street;
  final String city;
  final String zipCode;
  final String country;
  final bool isDefault;

  Address({
    required this.id,
    required this.label,
    required this.name,
    required this.street,
    required this.city,
    required this.zipCode,
    required this.country,
    this.isDefault = false,
  });

  String get fullAddress => '$street, $city, $zipCode, $country';
}

class AddressSelectionModal extends StatefulWidget {
  final Function(Address) onAddressSelected;

  const AddressSelectionModal({super.key, required this.onAddressSelected});

  @override
  State<AddressSelectionModal> createState() => _AddressSelectionModalState();
}

class _AddressSelectionModalState extends State<AddressSelectionModal> {
  List<Address> addresses = [];
  bool _showAddForm = false;

  @override
  void initState() {
    super.initState();
    _loadMockAddresses();
  }

  void _loadMockAddresses() {
    addresses = [
      Address(
        id: '1',
        label: 'Home',
        name: 'Home',
        street: '123 Main Street',
        city: 'Mogadishu',
        zipCode: '1000',
        country: 'Somalia',
        isDefault: true,
      ),
      Address(
        id: '2',
        label: 'Work',
        name: 'Work',
        street: '45 Business Avenue',
        city: 'Hargeisa',
        zipCode: '2000',
        country: 'Somalia',
        isDefault: false,
      ),
    ];
  }

  void _addAddress(Address newAddress) {
    setState(() {
      addresses.add(newAddress);
      _showAddForm = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address added successfully'),
        backgroundColor: Color(0xFF2ED573),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (_showAddForm)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        onPressed: () {
                          setState(() => _showAddForm = false);
                        },
                      ),
                    Text(
                      _showAddForm ? 'Add New Address' : 'Select Address',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Iconsax.close_circle),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ✅ FIX: Conditional rendering - show form OR list, never both
          if (_showAddForm) ...[
            Expanded(
              child: SingleChildScrollView(
                child: AddAddressForm(onAddressAdded: _addAddress),
              ),
            ),
          ] else ...[
            // Add New Address Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => _showAddForm = true);
                },
                icon: const Icon(Iconsax.add, color: Colors.white),
                label: const Text('Add New Address'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ED573),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Address List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: addresses.length,
                itemBuilder: (context, index) {
                  final address = addresses[index];
                  return AddressCard(
                    address: address,
                    onSelect: () {
                      widget.onAddressSelected(address);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Address Card Widget
class AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onSelect;

  const AddressCard({super.key, required this.address, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: address.isDefault
              ? const Color(0xFF2ED573)
              : const Color(0xFFEEEEEE),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      address.label == 'Home'
                          ? Iconsax.home
                          : address.label == 'Work'
                          ? Iconsax.building
                          : Iconsax.location,
                      size: 20,
                      color: const Color(0xFF2ED573),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      address.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                          color: const Color(0xFF2ED573).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
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
                const SizedBox(height: 8),
                Text(
                  address.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address.fullAddress,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
