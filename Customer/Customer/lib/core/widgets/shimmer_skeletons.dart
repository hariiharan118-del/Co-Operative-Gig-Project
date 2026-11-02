import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme.dart';
import 'motion.dart';

class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFDCECEE),
      highlightColor: const Color(0xFFF4FAFB),
      period: const Duration(milliseconds: 1200),
      child: child,
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    this.width,
    this.height = 12,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class ListingCardSkeleton extends StatelessWidget {
  const ListingCardSkeleton({super.key, this.tall = false});

  final bool tall;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.border),
        ),
        width: double.infinity,
        height: double.infinity,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ColoredBox(
              color: AppColors.border,
              child: SizedBox(height: 130, width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Bone(height: 14, radius: 6),
                  const SizedBox(height: 8),
                  const _Bone(width: 96, height: 10, radius: 6),
                  if (tall) ...[
                    const SizedBox(height: 10),
                    const _Bone(width: 72, height: 10, radius: 6),
                    const SizedBox(height: 12),
                    const _Bone(width: 120, height: 22, radius: 99),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListingGridSkeletonSliver extends StatelessWidget {
  const ListingGridSkeletonSliver({
    super.key,
    this.count = 4,
    this.tall = false,
    this.bottomPadding = 0,
  });

  final int count;
  final bool tall;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: tall ? 308 : 208,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return StaggeredFadeSlide(
              index: index,
              child: ListingCardSkeleton(tall: tall),
            );
          },
          childCount: count,
        ),
      ),
    );
  }
}

class HistoryListSkeleton extends StatelessWidget {
  const HistoryListSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return StaggeredFadeSlide(
          index: index,
          child: AppShimmer(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      _Bone(width: 40, height: 40, radius: 12),
                      SizedBox(width: 12),
                      Expanded(child: _Bone(height: 14, radius: 6)),
                      SizedBox(width: 12),
                      _Bone(width: 72, height: 22, radius: 99),
                    ],
                  ),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _Bone(height: 12, radius: 6)),
                      SizedBox(width: 24),
                      _Bone(width: 56, height: 12, radius: 6),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
