import 'package:flutter/material.dart';

class TokenProvider extends InheritedWidget {
  final String token;

  const TokenProvider({super.key, required this.token, required super.child});

  static TokenProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TokenProvider>();
  }

  @override
  bool updateShouldNotify(TokenProvider oldWidget) {
    return token != oldWidget.token;
  }
}
