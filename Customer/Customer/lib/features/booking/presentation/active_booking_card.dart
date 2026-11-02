import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/visual_style.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../history/data/mock_bookings.dart';
import '../domain/models.dart';
import '../providers/live_bookings_provider.dart';

class ActiveBookingBanner extends ConsumerWidget {
  const ActiveBookingBanner({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 0),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeBookingProvider);
    if (active == null) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: ActiveBookingCard(snapshot: active),
    );
  }
}

class ActiveBookingCard extends StatelessWidget {
  const ActiveBookingCard({super.key, required this.snapshot});

  final ActiveBookingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final booking = snapshot.booking;
    final worker = booking.worker;
    final statusText = trackingStatusLabel(booking.status);
    final detail = worker != null && worker.name.isNotEmpty
        ? worker.name
        : 'home.activeBookingHint'.tr();
    final eta = snapshot.etaMinutes;

    return AppCard(
      onTap: () => context.push(booking.livePath, extra: booking),
      padding: const EdgeInsets.all(16),
      color: AppColors.primarySoft,
      borderColor: AppColors.primary.withValues(alpha: 0.22),
      child: Row(
        children: [
          CategoryGlyph(category: booking.categoryName, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'home.activeBooking'.tr(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  booking.categoryName,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  eta != null
                      ? '$detail · ${'tracking.eta'.tr(args: ['$eta min'])}'
                      : detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(
                label: statusText,
                emoji: statusEmoji(booking.status),
                tone: booking.status == BookingStatus.requested
                    ? AlertTone.warning
                    : AlertTone.info,
              ),
              const SizedBox(height: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
