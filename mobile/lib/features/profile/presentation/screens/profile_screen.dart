import 'package:flutter/material.dart';
import 'package:mobile/features/profile/presentation/providers/profile_provider.dart';

import 'package:provider/provider.dart';
import 'profile_view.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider(),
      child: const ProfileView(),
    );
  }
}
