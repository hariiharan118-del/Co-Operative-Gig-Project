import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import '../visual_style.dart';
import 'motion.dart';

class SkyScaffold extends StatelessWidget {
  const SkyScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.header,
    this.trailing,
    this.showBack = false,
    this.overlap = true,
  });

  final String title;
  final String? subtitle;
  final Widget? header;
  final Widget body;
  final Widget? trailing;
  final bool showBack;
  final bool overlap;

  @override
  Widget build(BuildContext context) {
    final topBar = Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBack)
                CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () {
                    if (context.canPop()) context.pop();
                  },
                ),
              if (showBack) const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ],
          if (header != null) ...[
            const SizedBox(height: 14),
            header!,
          ],
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!constraints.hasBoundedHeight || constraints.maxHeight < 80) {
              return const SizedBox.expand();
            }
            return Column(
              children: [
                topBar,
                Expanded(child: body),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SkyCard extends StatelessWidget {
  const SkyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = AppColors.card,
    this.onTap,
    this.borderColor,
    this.entranceIndex,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;
  final Color? borderColor;
  final int? entranceIndex;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: BorderSide(color: borderColor ?? AppColors.border),
    );
    final content = Padding(padding: padding, child: child);

    final card = Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? SizedBox(width: double.infinity, child: content)
          : InkWell(
              onTap: onTap,
              customBorder: shape,
              child: SizedBox(width: double.infinity, child: content),
            ),
    );
    final index = entranceIndex;
    if (index == null) return card;
    return StaggeredEntrance(index: index, child: card);
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.background = AppColors.surface,
    this.foreground = AppColors.ink,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: foreground, size: size * 0.48),
        ),
      ),
    );
  }
}

class PillToggle extends StatelessWidget {
  const PillToggle({
    super.key,
    required this.left,
    required this.right,
    required this.value,
    required this.onChanged,
  });

  final String left;
  final String right;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(child: _seg(label: left, selected: value, onTap: () => onChanged(true))),
          Expanded(child: _seg(label: right, selected: !value, onTap: () => onChanged(false))),
        ],
      ),
    );
  }

  Widget _seg({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class SkyChip extends StatelessWidget {
  const SkyChip({
    super.key,
    required this.label,
    this.color = AppColors.accent,
    this.filled = false,
    this.emoji,
  });

  final String label;
  final Color color;
  final bool filled;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final mark = switch (emoji) {
      null => statusEmojiFor(label),
      '' => null,
      final value => value,
    };
    return AnimatedSwitcher(
      duration: AppMotion.badge,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: Container(
        key: ValueKey('$label-$color-$filled-$mark'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mark != null) ...[
              Text(mark, style: const TextStyle(fontSize: 11, height: 1)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RouteTrail extends StatelessWidget {
  const RouteTrail({
    super.key,
    required this.fromCode,
    required this.toCode,
    required this.fromLabel,
    required this.toLabel,
    this.icon = Icons.handyman_outlined,
  });

  final String fromCode;
  final String toCode;
  final String fromLabel;
  final String toLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              fromCode,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(height: 1, color: AppColors.line),
              ),
            ),
            Text(
              toCode,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                fromLabel,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
            Expanded(
              child: Text(
                toLabel,
                textAlign: TextAlign.right,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(
        Icons.handshake_rounded,
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }
}

enum AlertTone { error, warning, info }

class AlertBanner extends StatelessWidget {
  const AlertBanner({
    super.key,
    required this.title,
    required this.body,
    this.tone = AlertTone.error,
  });

  final String title;
  final String body;
  final AlertTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      AlertTone.error => (
        AppColors.errorSoft,
        AppColors.error,
        Icons.error_outline,
      ),
      AlertTone.warning => (
        AppColors.warningSoft,
        AppColors.warning,
        Icons.warning_amber_rounded,
      ),
      AlertTone.info => (
        AppColors.primarySoft,
        AppColors.primary,
        Icons.info_outline,
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(colors.$3, color: colors.$2),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.$2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(color: colors.$2, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VerifyingOverlay extends StatelessWidget {
  const VerifyingOverlay({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.72),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: const TextStyle(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

