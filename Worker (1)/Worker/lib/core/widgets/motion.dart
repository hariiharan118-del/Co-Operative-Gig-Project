import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme.dart';

class AppMotion {
  AppMotion._();

  static const Duration press = Duration(milliseconds: 120);
  static const Duration card = Duration(milliseconds: 280);
  static const Duration badge = Duration(milliseconds: 250);
  static const Duration star = Duration(milliseconds: 160);
  static const int staggerMs = 50;
}

/// Fade + slight upward slide, delayed by [index] * 50ms.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
  });

  final Widget child;
  final int index;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    final delayMs = (widget.index * AppMotion.staggerMs).clamp(0, 400);
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.08),
      duration: AppMotion.card,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: AppMotion.card,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Scales to 0.96 while the pointer is down.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
      onTapUp: widget.enabled ? (_) => _setPressed(false) : null,
      onTapCancel: widget.enabled ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: AppMotion.press,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Interactive 1–5 stars; the tapped star pops to 1.2× then settles.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 32,
  });

  final int value;
  final ValueChanged<int>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          _PopStar(
            filled: i <= value,
            size: size,
            onTap: onChanged == null ? null : () => onChanged!(i),
          ),
      ],
    );
  }
}

class _PopStar extends StatefulWidget {
  const _PopStar({
    required this.filled,
    required this.size,
    this.onTap,
  });

  final bool filled;
  final double size;
  final VoidCallback? onTap;

  @override
  State<_PopStar> createState() => _PopStarState();
}

class _PopStarState extends State<_PopStar> {
  double _scale = 1;

  Future<void> _handleTap() async {
    widget.onTap?.call();
    setState(() => _scale = 1.2);
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (mounted) setState(() => _scale = 1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap == null ? null : _handleTap,
      child: AnimatedScale(
        scale: _scale,
        duration: AppMotion.star,
        curve: Curves.easeOutBack,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            widget.filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: widget.size,
            color: widget.filled ? AppColors.starFilled : AppColors.starEmpty,
          ),
        ),
      ),
    );
  }
}

class ShimmerScope extends StatelessWidget {
  const ShimmerScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: child,
    );
  }
}

class ShimmerBlock extends StatelessWidget {
  const ShimmerBlock({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 8,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Card-shaped placeholders matching the job-feed item layout.
class JobFeedSkeleton extends StatelessWidget {
  const JobFeedSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        itemCount: count + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const ShimmerBlock(width: 140, height: 18, radius: 6);
          }
          return const _JobCardSkeleton();
        },
      ),
    );
  }
}

class _JobCardSkeleton extends StatelessWidget {
  const _JobCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerBlock(width: 44, height: 44, radius: 12),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBlock(width: 120, height: 16),
                    SizedBox(height: 8),
                    ShimmerBlock(width: 80, height: 12),
                  ],
                ),
              ),
              ShimmerBlock(width: 56, height: 20),
            ],
          ),
          SizedBox(height: 16),
          ShimmerBlock(height: 14),
          SizedBox(height: 8),
          ShimmerBlock(width: 180, height: 12),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ShimmerBlock(height: 46, radius: 10)),
              SizedBox(width: 10),
              Expanded(child: ShimmerBlock(height: 46, radius: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Generic card-row skeletons for list/grid loading states.
class CardListSkeleton extends StatelessWidget {
  const CardListSkeleton({
    super.key,
    this.count = 4,
    this.height = 88,
  });

  final int count;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
        ),
      ),
    );
  }
}
