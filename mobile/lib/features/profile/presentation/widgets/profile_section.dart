import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/profile/presentation/screens/profile_screen.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'EN',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2ED573),
              ),
            ),
          ),
        ),
        title: const Text(
          'Eng Soke',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        subtitle: const Text(
          '616739858',
          style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
        ),
        trailing: const Icon(
          Iconsax.arrow_right_3,
          size: 24,
          color: Color(0xFF333333),
        ),
        onTap: () {
          // Navigate to profile details
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen()),
          );
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('Navigate to Profile Details'),
          //     duration: Duration(seconds: 1),
          //   ),
          // );
        },
      ),
    );
  }
}
