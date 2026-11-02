import 'package:flutter/material.dart';

import '../theme.dart';
import '../visual_style.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56, this.onTeal = false});

  final double size;
  final bool onTeal;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.22;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        Icons.handshake_rounded,
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    this.subtitle,
    this.compact = false,
    this.onTeal = false,
  });

  final String? subtitle;
  final bool compact;
  final bool onTeal;

  @override
  Widget build(BuildContext context) {
    final titleColor = onTeal ? AppColors.headingOnTeal : AppColors.navy;
    final subtitleColor = onTeal ? AppColors.mutedOnTeal : AppColors.muted;
    return Column(
      children: [
        BrandMark(size: compact ? 44 : 56, onTeal: onTeal),
        SizedBox(height: compact ? 10 : 14),
        Text(
          'KRIYANTA',
          style: TextStyle(
            color: titleColor,
            fontSize: compact ? 22 : 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.borderColor,
    this.color = AppColors.card,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: BorderSide(color: borderColor ?? AppColors.border),
    );
    final content = Padding(padding: padding, child: child);

    return Material(
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
  }
}

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
      AlertTone.error => (AppColors.errorSoft, AppColors.error, Icons.error_outline),
      AlertTone.warning => (AppColors.warningSoft, AppColors.warning, Icons.warning_amber_rounded),
      AlertTone.info => (AppColors.primarySoft, AppColors.primary, Icons.info_outline),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(16),
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
                  style: TextStyle(color: colors.$2, fontWeight: FontWeight.w700),
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

enum AlertTone { error, warning, info }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
    this.emoji,
  });

  final String label;
  final AlertTone tone;
  final IconData? icon;
  /// Pass `''` to hide the status emoji. Otherwise looked up from [label].
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final bg = switch (tone) {
      AlertTone.error => AppColors.errorSoft,
      AlertTone.warning => AppColors.accentSoft,
      AlertTone.info => AppColors.primarySoft,
    };
    final fg = switch (tone) {
      AlertTone.error => AppColors.error,
      AlertTone.warning => AppColors.warning,
      AlertTone.info => AppColors.primary,
    };
    final mark = (emoji != null && emoji!.isEmpty)
        ? null
        : (emoji ?? statusEmojiFor(label));
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Container(
        key: ValueKey('$label-$tone'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mark != null) ...[
              Text(mark, style: const TextStyle(fontSize: 12, height: 1)),
              const SizedBox(width: 4),
            ] else if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SuccessChip extends StatelessWidget {
  const SuccessChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final mark = statusEmojiFor(label) ?? '✅';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mark, style: const TextStyle(fontSize: 12, height: 1)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
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

class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color ?? AppColors.primary, size: 20),
    );
  }
}
