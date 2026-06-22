import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ==========================================
// BASE SHIMMER CONTAINER
// ==========================================
class ShimmerContainer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerContainer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ==========================================
// 1. STATS SKELETON (4 Cards in Grid)
// ==========================================
class StatsSkeleton extends StatelessWidget {
  const StatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: List.generate(4, (index) => _buildStatCardSkeleton()),
    );
  }

  Widget _buildStatCardSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerContainer(width: 60, height: 12),
                ShimmerContainer(width: 28, height: 28, borderRadius: 8),
              ],
            ),
            const SizedBox(height: 6),
            ShimmerContainer(width: 80, height: 20),
            const SizedBox(height: 4),
            ShimmerContainer(width: 50, height: 10),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. PERIOD SELECTOR SKELETON
// ==========================================
class PeriodSelectorSkeleton extends StatelessWidget {
  const PeriodSelectorSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: ShimmerContainer(width: 40, height: 12)),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ==========================================
// 3. LINE CHART SKELETON
// ==========================================
class LineChartSkeleton extends StatelessWidget {
  const LineChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerContainer(width: 120, height: 16),
            const SizedBox(height: 20),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomPaint(
                size: const Size(double.infinity, 200),
                painter: _LineChartSkeletonPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartSkeletonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.4,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// 4. BAR CHART SKELETON
// ==========================================
class BarChartSkeleton extends StatelessWidget {
  const BarChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerContainer(width: 120, height: 16),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(5, (index) {
                  final heights = [0.4, 0.7, 0.5, 0.9, 0.6];
                  return Container(
                    width: 16,
                    height: 180 * heights[index],
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. QUICK ACTIONS SKELETON (2 Cards)
// ==========================================
class QuickActionsSkeleton extends StatelessWidget {
  const QuickActionsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildActionCardSkeleton()),
        const SizedBox(width: 16),
        Expanded(child: _buildActionCardSkeleton()),
      ],
    );
  }

  Widget _buildActionCardSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            ShimmerContainer(width: 52, height: 52, borderRadius: 26),
            const SizedBox(height: 12),
            ShimmerContainer(width: 80, height: 14),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. RECENT ORDERS SKELETON
// ==========================================
class RecentOrdersSkeleton extends StatelessWidget {
  final int itemCount;

  const RecentOrdersSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: List.generate(
            itemCount,
            (index) => Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              child: Row(
                children: [
                  ShimmerContainer(width: 40, height: 40, borderRadius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerContainer(width: 120, height: 14),
                        const SizedBox(height: 6),
                        ShimmerContainer(width: 180, height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ShimmerContainer(width: 70, height: 24, borderRadius: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 7. SECTION TITLE SKELETON
// ==========================================
class SectionTitleSkeleton extends StatelessWidget {
  const SectionTitleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerContainer(width: 150, height: 18);
  }
}
