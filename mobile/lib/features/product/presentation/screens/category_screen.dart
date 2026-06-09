import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/product_bloc.dart';
import '../blocs/product_event.dart';
import 'category_view.dart';

class CategoryScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const CategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    // Remove ToastificationWrapper from here
    // Trigger products load when screen opens
    context.read<ProductBloc>().add(GetProductsByCategoryEvent(categoryId));

    return CategoryView(categoryId: categoryId, categoryName: categoryName);
  }
}
