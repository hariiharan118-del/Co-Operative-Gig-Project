import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/motion.dart';
import '../../auth/providers/auth_provider.dart';
import '../../history/data/mock_bookings.dart';
import '../domain/models.dart';
import '../providers/booking_providers.dart';
import '../providers/live_bookings_provider.dart';

class ConfirmStepScreen extends ConsumerStatefulWidget {
  const ConfirmStepScreen({super.key});

  @override
  ConsumerState<ConfirmStepScreen> createState() => _ConfirmStepScreenState();
}

class _ConfirmStepScreenState extends ConsumerState<ConfirmStepScreen> {
  late final TextEditingController _notes;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController(text: ref.read(bookingDraftProvider).notes);
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    ref.read(bookingDraftProvider.notifier).setNotes(_notes.text.trim());
    final draft = ref.read(bookingDraftProvider);
    final categoryId = draft.categoryId;
    final address = draft.address;
    if (categoryId == null || address == null) return;

    setState(() => _busy = true);
    try {
      final auth = ref.read(authProvider);
      if (isDemoSession(auth)) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        ref.read(liveBookingsProvider.notifier).upsert(trackingSeed('bkg_live'));
        context.go('/tracking/bkg_live');
        return;
      }

      final booking = await ref.read(bookingsRepositoryProvider).create(
            serviceCategoryId: categoryId,
            addressId: address.id,
            scheduledAt: draft.timing == BookingTiming.scheduled
                ? draft.scheduledAt
                : null,
            isEmergency: draft.timing == BookingTiming.instant,
          );
      ref.invalidate(myBookingsProvider);
      ref.read(liveBookingsProvider.notifier).upsert(booking);
      if (!mounted) return;
      context.go('/tracking/${booking.id}');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingDraftProvider);
    final when = draft.timing == BookingTiming.instant
        ? 'booking.instant'.tr()
        : (draft.scheduledAt != null
            ? DateFormat('EEE d MMM, h:mm a').format(draft.scheduledAt!)
            : 'booking.scheduled'.tr());

    return Scaffold(
      appBar: AppBar(title: Text('booking.confirmTitle'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Row(label: 'booking.category'.tr(), value: draft.categoryName ?? '—'),
          _Row(
            label: 'booking.address'.tr(),
            value: draft.address?.fullLine ?? '—',
          ),
          _Row(label: 'booking.when'.tr(), value: when),
          _Row(
            label: 'booking.estimatedPrice'.tr(),
            value: formatPaise(draft.estimatedPricePaise),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'booking.notesLabel'.tr(),
              hintText: 'booking.notesHint'.tr(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: PressScale(
            enabled: !_busy,
            child: FilledButton(
              onPressed: _busy ? null : _confirm,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('booking.confirmCta'.tr()),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
