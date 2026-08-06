// lib/features/product/presentation/widgets/loading/subcategories_skeleton.dart

import 'package:flutter/material.dart';
import 'package:mobile/core/common/widgets/skeleton_widget.dart';

class SubcategoriesSkeleton extends StatelessWidget {
  const SubcategoriesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SkeletonWidget(
              width: 80 + (index * 10.0), // Varying widths for realism
              height: 36,
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}
