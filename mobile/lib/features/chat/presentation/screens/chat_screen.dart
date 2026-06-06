import 'package:flutter/material.dart';

import 'chat_view.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: ChatView());
  }
}
