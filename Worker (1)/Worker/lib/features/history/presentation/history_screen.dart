import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../core/visual_style.dart';
import '../../../core/widgets/sky_widgets.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final dateFmt = DateFormat.MMMd();

    return SkyScaffold(
      title: 'history.title'.tr(),
      subtitle: 'history.hero'.tr(),
      trailing: CircleIconButton(
        icon: Icons.refresh_rounded,
        onPressed: historyAsync.isLoading
            ? null
            : () => ref.invalidate(historyProvider),
      ),
      body: historyAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'common.error'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(historyProvider),
                  child: Text('common.retry'.tr()),
                ),
              ],
            ),
          ),
        ),
        data: (items) => items.isEmpty
            ? Center(
                child: InvitationEmpty(
                  emoji: '📭',
                  message: 'history.empty'.tr(),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(historyProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final job = items[index];
                    return SkyCard(
                      key: ValueKey(job.id),
                      entranceIndex: index,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CategoryGlyph(category: job.serviceType),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  job.serviceType,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              SkyChip(
                                label: dateFmt.format(job.completedAt),
                                emoji: '',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          RouteTrail(
                            fromCode: 'YOU',
                            toCode: job.areaCode,
                            fromLabel: job.customerName,
                            toLabel: job.areaName,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  job.addressLine,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                formatPaise(job.earnedPaise),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.teal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
