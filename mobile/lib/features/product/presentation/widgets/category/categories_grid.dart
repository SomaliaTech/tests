import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/category_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/category_event.dart';
import 'package:mobile/features/product/presentation/blocs/category_state.dart';

import 'category_item.dart';

class CategoriesGrid extends StatelessWidget {
  final int? limit;

  const CategoriesGrid({super.key, this.limit});

  @override
  Widget build(BuildContext context) {
    context.read<CategoryBloc>().add(GetParentCategoriesEvent());

    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is ParentCategoriesLoaded) {
          final displayCategories = limit != null
              ? state.categories.take(limit!).toList()
              : state.categories;

          return GridView.builder(
            padding: const EdgeInsets.only(top: 5),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 5,
              mainAxisSpacing: 15,
              childAspectRatio: 0.85,
            ),
            itemCount: displayCategories.length,
            itemBuilder: (context, index) {
              return CategoryItem(category: displayCategories[index]);
            },
          );
        } else if (state is CategoriesLoading) {
          return const Center(
            child: SizedBox(height: 100, child: CircularProgressIndicator()),
          );
        } else if (state is CategoriesError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(state.message),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
