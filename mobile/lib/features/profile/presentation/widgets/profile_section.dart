import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/profile/presentation/screens/profile_screen.dart';

class ProfileSection extends StatelessWidget {
  final String? userName;
  final String? userPhone;
  final String? profileImage;

  const ProfileSection({
    super.key,
    this.userName,
    this.userPhone,
    this.profileImage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Profile Image with error handling
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8F5E9),
              ),
              child: ClipOval(
                child: (profileImage != null && profileImage!.isNotEmpty)
                    ? Image.network(
                        profileImage!,
                        fit: BoxFit.cover,
                        // ✅ Handle loading state
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: const Color(0xFFE8F5E9),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2ED573),
                              ),
                            ),
                          );
                        },
                        // ✅ Handle error state - PREVENTS CRASH
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('⚠️ Profile image load error: $error');
                          return Container(
                            color: const Color(0xFFE8F5E9),
                            child: const Icon(
                              Iconsax.user,
                              size: 35,
                              color: Color(0xFF999999),
                            ),
                          );
                        },
                      )
                    : const Icon(
                        Iconsax.user,
                        size: 35,
                        color: Color(0xFF999999),
                      ),
              ),
            ),

            const SizedBox(width: 16),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName ?? 'User Name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userPhone ?? 'Phone Number',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Edit Profile Button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ED573).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Iconsax.edit,
                      size: 14,
                      color: Color(0xFF2ED573),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF2ED573),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
