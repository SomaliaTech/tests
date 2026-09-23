class SupportContact {
  final String email;
  final String phoneNumber;

  const SupportContact({required this.email, required this.phoneNumber});

  factory SupportContact.fromJson(Map<String, dynamic> json) {
    return SupportContact(
      email: json['email']?.toString() ?? 'support@farxada.com',
      phoneNumber: json['phoneNumber']?.toString() ?? '+252615328651',
    );
  }

  Map<String, dynamic> toJson() => {'email': email, 'phoneNumber': phoneNumber};
}
