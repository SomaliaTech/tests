import 'package:flutter/material.dart';
import '../../../../core/common/widgets/skeleton_widget.dart';

class CategoryItemSkeleton extends StatelessWidget {
  const CategoryItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Circle skeleton
        SkeletonWidget(
          width: 65,
          height: 65,
          borderRadius: BorderRadius.circular(32.5),
        ),
        const SizedBox(height: 8),
        // Text skeleton
        SkeletonWidget(
          width: 60,
          height: 12,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
