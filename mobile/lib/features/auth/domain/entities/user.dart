// lib/features/auth/domain/entities/user.dart
class User {
  final String id;
  final String phoneNumber;
  final String? name;
  final String? profileImage;
  final String? marketId;
  final String? email; // ✅ Add email
  final bool isVerified;
  final bool hasProfile;
  final bool isAdmin;
  final bool isSuperAdmin;

  User({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.profileImage,
    this.marketId,
    this.email, // ✅ Add email
    this.isVerified = false,
    this.hasProfile = false,
    this.isAdmin = false,
    this.isSuperAdmin = false,
  });

  // ✅ Add copyWith method for comparisons
  User copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? profileImage,
    String? marketId,
    String? email,
    bool? isVerified,
    bool? hasProfile,
    bool? isAdmin,
    bool? isSuperAdmin,
  }) {
    return User(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      marketId: marketId ?? this.marketId,
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
      hasProfile: hasProfile ?? this.hasProfile,
      isAdmin: isAdmin ?? this.isAdmin,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
    );
  }

  // ✅ Add equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.phoneNumber == phoneNumber &&
        other.name == name &&
        other.profileImage == profileImage &&
        other.marketId == marketId &&
        other.email == email;
  }

  @override
  int get hashCode =>
      Object.hash(id, phoneNumber, name, profileImage, marketId, email);
}
