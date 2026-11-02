import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/visual_style.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/ui_kit.dart';
import '../providers/booking_providers.dart';

class AddressStepScreen extends ConsumerWidget {
  const AddressStepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(savedAddressesProvider);
    final draft = ref.watch(bookingDraftProvider);

    return Scaffold(
      appBar: AppBar(title: Text('booking.pickAddress'.tr())),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                PressScale(
                  child: FilledButton(
                    onPressed: () => ref.invalidate(savedAddressesProvider),
                    child: Text('common.retry'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (addresses) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (addresses.isEmpty)
                InvitationEmpty(
                  emoji: '📍',
                  message: 'booking.noAddresses'.tr(),
                ),
              for (final address in addresses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      selected: draft.address?.id == address.id,
                      onTap: () {
                        ref.read(bookingDraftProvider.notifier).setAddress(address);
                      },
                      title: Text(address.label),
                      subtitle: Text(address.fullLine),
                      trailing: Icon(
                        draft.address?.id == address.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => context.push('/profile/addresses/new'),
                icon: const Icon(Icons.add),
                label: Text('booking.addAddress'.tr()),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: PressScale(
            enabled: draft.address != null,
            child: FilledButton(
              onPressed: draft.address == null
                  ? null
                  : () => context.push('/booking/schedule'),
              child: Text('booking.useThisAddress'.tr()),
            ),
          ),
        ),
      ),
    );
  }
}
