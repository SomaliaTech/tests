class Address {
  final String id;
  final String label;
  final String fullAddress;
  final String phoneNumber;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.phoneNumber,
    this.isDefault = false,
  });

  factory Address.mock() {
    return const Address(
      id: '1',
      label: 'Home',
      fullAddress: '123 Main Street, City, Country',
      phoneNumber: '+1234567890',
      isDefault: true,
    );
  }
}
