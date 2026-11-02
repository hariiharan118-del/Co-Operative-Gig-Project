import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/motion.dart';
import '../domain/models.dart';
import '../providers/booking_providers.dart';

class ScheduleStepScreen extends ConsumerWidget {
  const ScheduleStepScreen({super.key});

  static final _slots = <TimeOfDay>[
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 11, minute: 0),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 16, minute: 30),
    const TimeOfDay(hour: 18, minute: 0),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(bookingDraftProvider);
    final notifier = ref.read(bookingDraftProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('booking.scheduleTitle'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TimingCard(
            selected: draft.timing == BookingTiming.instant,
            title: 'booking.instant'.tr(),
            subtitle: 'booking.instantHint'.tr(),
            icon: Icons.bolt,
            onTap: () => notifier.setTiming(BookingTiming.instant),
          ),
          const SizedBox(height: 12),
          _TimingCard(
            selected: draft.timing == BookingTiming.scheduled,
            title: 'booking.scheduled'.tr(),
            subtitle: 'booking.scheduledHint'.tr(),
            icon: Icons.event,
            onTap: () {
              final now = DateTime.now().add(const Duration(hours: 2));
              notifier.setTiming(
                BookingTiming.scheduled,
                scheduledAt: DateTime(
                  now.year,
                  now.month,
                  now.day,
                  11,
                ),
              );
            },
          ),
          if (draft.timing == BookingTiming.scheduled) ...[
            const SizedBox(height: 20),
            Text(
              'booking.pickSlot'.tr(),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slot in _slots)
                  ChoiceChip(
                    label: Text(slot.format(context)),
                    selected: draft.scheduledAt != null &&
                        draft.scheduledAt!.hour == slot.hour &&
                        draft.scheduledAt!.minute == slot.minute,
                    onSelected: (_) {
                      final day = draft.scheduledAt ?? DateTime.now();
                      notifier.setTiming(
                        BookingTiming.scheduled,
                        scheduledAt: DateTime(
                          day.year,
                          day.month,
                          day.day,
                          slot.hour,
                          slot.minute,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: PressScale(
            child: FilledButton(
              onPressed: () => context.push('/booking/confirm'),
              child: Text('common.next'.tr()),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimingCard extends StatelessWidget {
  const _TimingCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: selected ? theme.colorScheme.primaryContainer : null,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: selected
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
            : const Icon(Icons.circle_outlined),
      ),
    );
  }
}
