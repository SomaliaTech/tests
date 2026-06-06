import 'package:flutter/material.dart';
import 'package:mobile/features/product/presentation/providers/category_provider.dart';
import 'package:provider/provider.dart';

import 'category_view.dart';

class CategoryScreen extends StatelessWidget {
  final String slug;

  const CategoryScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CategoryProvider()..loadCategory(slug),
      child: CategoryView(slug: slug),
    );
  }
}
