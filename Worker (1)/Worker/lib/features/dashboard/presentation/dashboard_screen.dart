import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_error.dart';
import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../core/visual_style.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/sky_widgets.dart';
import '../../job/domain/active_job.dart';
import '../../job/providers/active_job_provider.dart';
import '../domain/nearby_job.dart';
import '../providers/dashboard_providers.dart';
import '../../verification/domain/verification_state.dart';
import '../../verification/providers/verification_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(availabilityProvider);
    final jobsAsync = ref.watch(nearbyJobsProvider);
    final active = ref.watch(activeJobProvider);
    final verification = ref.watch(verificationProvider);
    final pinned = active != null && active.status.isOpen ? active : null;

    return SkyScaffold(
      title: 'dashboard.title'.tr(),
      subtitle: 'dashboard.hero'.tr(),
      header: PillToggle(
        left: 'dashboard.online'.tr(),
        right: 'dashboard.offline'.tr(),
        value: online,
        onChanged: (value) =>
            ref.read(availabilityProvider.notifier).setOnline(value),
      ),
      trailing: CircleIconButton(
        icon: Icons.refresh_rounded,
        onPressed: jobsAsync.isLoading
            ? null
            : () => ref.invalidate(nearbyJobsProvider),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (verification.isProbation)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _ProbationDashboardBanner(verification: verification),
            ),
          if (pinned != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _ActiveJobPin(job: pinned),
            ),
          Expanded(
            child: !online
                ? Center(
                    child: InvitationEmpty(
                      emoji: '📡',
                      message: 'dashboard.goOnline'.tr(),
                    ),
                  )
                : jobsAsync.when(
                    skipLoadingOnReload: true,
                    skipLoadingOnRefresh: true,
                    loading: () => const JobFeedSkeleton(),
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
                              onPressed: () =>
                                  ref.invalidate(nearbyJobsProvider),
                              child: Text('common.retry'.tr()),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (jobs) => jobs.isEmpty
                        ? Center(
                            child: InvitationEmpty(
                              emoji: '🔍',
                              message: 'dashboard.empty'.tr(),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.refresh(nearbyJobsProvider.future),
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 20, 16, 24),
                              itemCount: jobs.length + 1,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Text(
                                    'dashboard.nearbyTitle'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                }
                                final job = jobs[index - 1];
                                return _JobCard(
                                  key: ValueKey(job.id),
                                  job: job,
                                  entranceIndex: index - 1,
                                );
                              },
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActiveJobPin extends StatelessWidget {
  const _ActiveJobPin({required this.job});

  final ActiveJob job;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'dashboard.activeTitle'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        SkyCard(
          entranceIndex: 0,
          color: AppColors.accentSoft,
          onTap: () => context.push('/job/${job.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryGlyph(category: job.jobType),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.jobType,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          job.customerName,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatPaise(job.farePaise),
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SkyChip(label: job.status.labelKey.tr()),
              const SizedBox(height: 8),
              Text(
                'dashboard.activeHint'.tr(),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'dashboard.activeContinue'.tr(),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JobCard extends ConsumerStatefulWidget {
  const _JobCard({
    super.key,
    required this.job,
    this.entranceIndex = 0,
  });

  final NearbyJob job;
  final int entranceIndex;

  @override
  ConsumerState<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends ConsumerState<_JobCard> {
  bool _accepting = false;

  Future<void> _accept() async {
    if (_accepting) return;
    setState(() => _accepting = true);
    // Capture before accept() removes this card from the list (which
    // disposes this State). Navigation must not depend on [mounted].
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final feedJob = widget.job;
    try {
      final accepted =
          await ref.read(nearbyJobsProvider.notifier).accept(feedJob.id);
      final active = accepted.toActiveJob();
      ref.read(activeJobProvider.notifier).start(active);
      router.push('/job/${active.id}');
    } on JobTakenException {
      messenger.showSnackBar(
        SnackBar(
          content: Text('dashboard.jobTaken'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error, stack) {
      final detail = describeApiError(error);
      // print (not debugPrint / kDebugMode) so this stays in release logcat.
      // ignore: avoid_print
      print('[accept] $detail');
      // ignore: avoid_print
      print('[accept] $error');
      // ignore: avoid_print
      print('[accept] $stack');
      messenger.showSnackBar(
        SnackBar(
          content: Text(detail),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    return SkyCard(
      entranceIndex: widget.entranceIndex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryGlyph(category: job.serviceType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.serviceType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'dashboard.distance'.tr(
                        args: [job.distanceKm.toStringAsFixed(1)],
                      ),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatPaise(job.estimatedPayPaise),
                style: const TextStyle(
                  color: AppColors.teal,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RouteTrail(
            fromCode: 'YOU',
            toCode: job.areaCode,
            fromLabel: 'dashboard.here'.tr(),
            toLabel: job.areaName,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                  onPressed: _accepting
                      ? null
                      : () => ref
                          .read(nearbyJobsProvider.notifier)
                          .decline(job.id),
                  child: Text('dashboard.decline'.tr()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PressScale(
                  enabled: !_accepting,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: _accepting ? null : _accept,
                    child: _accepting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('dashboard.accept'.tr()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProbationDashboardBanner extends StatelessWidget {
  const _ProbationDashboardBanner({required this.verification});

  final VerificationState verification;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Community Verified (Probation)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '${verification.probationJobCount}/${verification.probationJobCountRequired} jobs completed · Min rating: ${verification.probationMinRating.toStringAsFixed(1)} ★ · Max ₹${verification.probationJobValueCap.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
