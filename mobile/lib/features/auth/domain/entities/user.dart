class User {
  final String id;
  final String phoneNumber;
  final String? name;
  final String? profileImage;
  final bool isVerified;
  final bool hasProfile;
  final bool? isAdmin;
  final bool? isSuperAdmin; // ✅ Add this
  final String? marketId;
  final String? email;

  User({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.profileImage,
    required this.isVerified,
    required this.hasProfile,
    this.isAdmin,
    this.isSuperAdmin, // ✅ Add this
    this.marketId,
    this.email,
  });
}
