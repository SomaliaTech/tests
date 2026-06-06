import 'package:flutter/material.dart';
import 'home_view.dart';

class HomeScreen extends StatelessWidget {
  static Route route = MaterialPageRoute(builder: (context) => HomeScreen());

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeView();
  }
}
