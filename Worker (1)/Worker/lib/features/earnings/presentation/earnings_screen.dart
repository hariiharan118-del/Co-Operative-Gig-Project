import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/sky_widgets.dart';
import '../domain/earnings_models.dart';
import '../providers/earnings_provider.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(earningsProvider);
    final dateFmt = DateFormat.MMMd().add_jm();

    return SkyScaffold(
      title: 'earnings.title'.tr(),
      subtitle: 'earnings.hero'.tr(),
      trailing: CircleIconButton(
        icon: Icons.refresh_rounded,
        onPressed: () => ref.invalidate(earningsProvider),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(earningsProvider),
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'earnings.balance'.tr(),
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  formatPaise(wallet.balancePaise),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                PressScale(
                  enabled: wallet.balancePaise > 0,
                  child: FilledButton(
                    onPressed: wallet.balancePaise <= 0
                        ? null
                        : () => _requestPayout(
                              context,
                              ref,
                              wallet.balancePaise,
                            ),
                    child: Text('earnings.requestPayout'.tr()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'earnings.recent'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...wallet.transactions.asMap().entries.map((entry) {
            final txn = entry.value;
            final credit = txn.type == TransactionType.credit;
            final color = credit ? AppColors.teal : AppColors.danger;
            final sign = credit ? '+' : '−';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SkyCard(
                key: ValueKey(txn.id),
                entranceIndex: entry.key,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        credit ? Icons.south_west_rounded : Icons.north_east_rounded,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            txn.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            dateFmt.format(txn.at),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$sign${formatPaise(txn.amountPaise)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        ),
      ),
    );
  }

  Future<void> _requestPayout(
    BuildContext context,
    WidgetRef ref,
    int balancePaise,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('earnings.requestPayout'.tr()),
        content: Text(
          'earnings.payoutConfirm'.tr(args: [formatPaise(balancePaise)]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          PressScale(
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('common.confirm'.tr()),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(earningsProvider.notifier).requestPayout(balancePaise);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('earnings.payoutRequested'.tr())),
        );
      }
    }
  }
}
