import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/visual_style.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/sky_widgets.dart';
import '../domain/welfare_models.dart';
import '../providers/welfare_provider.dart';

class WelfareScreen extends ConsumerStatefulWidget {
  const WelfareScreen({super.key});

  @override
  ConsumerState<WelfareScreen> createState() => _WelfareScreenState();
}

class _WelfareScreenState extends ConsumerState<WelfareScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(welfareProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(welfareProvider);
    final dateFmt = DateFormat.yMMMd();

    return SkyScaffold(
      title: 'welfare.title'.tr(),
      showBack: true,
      trailing: CircleIconButton(
        icon: Icons.refresh_rounded,
        onPressed: () => ref.read(welfareProvider.notifier).refresh(),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(welfareProvider.notifier).refresh(),
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          _EnrollmentCard(enrollment: snapshot.enrollment),
          const SizedBox(height: 22),
          Text(
            'welfare.claims'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (snapshot.claims.isEmpty)
            InvitationEmpty(
              emoji: '📋',
              message: 'welfare.emptyClaims'.tr(),
            )
          else
            ...snapshot.claims.asMap().entries.map((entry) {
              final claim = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SkyCard(
                  key: ValueKey(claim.id),
                  entranceIndex: entry.key,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              claim.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              claim.description,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dateFmt.format(claim.filedAt),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ClaimBadge(status: claim.status),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          PressScale(
            child: FilledButton(
              onPressed: () {
                context.push('${GoRouterState.of(context).uri.path}/claim');
              },
              child: Text('welfare.fileClaim'.tr()),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _EnrollmentCard extends StatelessWidget {
  const _EnrollmentCard({required this.enrollment});

  final WelfareEnrollment enrollment;

  @override
  Widget build(BuildContext context) {
    final (label, chipColor) = switch (enrollment.status) {
      EnrollmentStatus.enrolled => ('welfare.enrolled'.tr(), AppColors.gold),
      EnrollmentStatus.pending => ('welfare.pending'.tr(), AppColors.gold),
      EnrollmentStatus.notEnrolled => (
          'welfare.notEnrolled'.tr(),
          AppColors.danger,
        ),
    };

    return SkyCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            enrollment.planName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SkyChip(label: label, color: chipColor, filled: true),
          if (enrollment.coverageNote != null) ...[
            const SizedBox(height: 10),
            Text(
              enrollment.coverageNote!,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClaimBadge extends StatelessWidget {
  const _ClaimBadge({required this.status});

  final ClaimStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ClaimStatus.submitted => ('welfare.claimSubmitted'.tr(), AppColors.gold),
      ClaimStatus.approved => ('welfare.claimApproved'.tr(), AppColors.teal),
      ClaimStatus.rejected => ('welfare.claimRejected'.tr(), AppColors.danger),
      ClaimStatus.paid => ('welfare.claimPaid'.tr(), AppColors.teal),
    };
    return SkyChip(
      label: label,
      color: color,
      filled: status == ClaimStatus.paid || status == ClaimStatus.approved,
    );
  }
}

class FileClaimScreen extends ConsumerStatefulWidget {
  const FileClaimScreen({super.key});

  @override
  ConsumerState<FileClaimScreen> createState() => _FileClaimScreenState();
}

class _FileClaimScreenState extends ConsumerState<FileClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  String _category = claimCategories.first;
  bool _busy = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(welfareProvider.notifier).fileClaim(
            category: _category,
            description: _description.text.trim(),
          );
      if (!mounted) return;
      context.pop();
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
    return SkyScaffold(
      title: 'welfare.fileClaim'.tr(),
      showBack: true,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            SkyCard(
              child: DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'welfare.category'.tr(),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                items: [
                  for (final category in claimCategories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
            ),
            const SizedBox(height: 12),
            SkyCard(
              child: TextFormField(
                controller: _description,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'welfare.description'.tr(),
                  alignLabelWithHint: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < 8) {
                    return 'welfare.descriptionRequired'.tr();
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            PressScale(
              enabled: !_busy,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text('welfare.submitClaim'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
