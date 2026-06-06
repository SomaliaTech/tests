import 'package:flutter/material.dart';
import 'package:mobile/features/support/providers/support_provider.dart';
import 'package:provider/provider.dart';
import 'support_view.dart';

class SupportScreen extends StatelessWidget {
  static Route route() {
    return MaterialPageRoute(builder: (context) => SupportScreen());
  }

  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SupportProvider(),
      child: const SupportView(),
    );
  }
}
