import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/sky_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../domain/verification_state.dart';
import '../providers/verification_provider.dart';

class VerificationGateScreen extends ConsumerStatefulWidget {
  const VerificationGateScreen({super.key});

  @override
  ConsumerState<VerificationGateScreen> createState() =>
      _VerificationGateScreenState();
}

class _VerificationGateScreenState extends ConsumerState<VerificationGateScreen> {
  bool _showApplicationForm = false;

  @override
  Widget build(BuildContext context) {
    final verification = ref.watch(verificationProvider);

    if (_showApplicationForm ||
        verification.status == VerificationStatus.registered) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('verification.registeredTitle'.tr()),
          leading: verification.status != VerificationStatus.registered
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _showApplicationForm = false),
                )
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(verificationProvider.notifier).load(),
            ),
          ],
        ),
        body: _VerificationApplicationForm(
          onSubmitted: () {
            setState(() => _showApplicationForm = false);
            ref.read(verificationProvider.notifier).load();
          },
        ),
      );
    }

    final (emoji, color, title, body) = switch (verification.status) {
      VerificationStatus.registered => (
          '📝',
          AppColors.primary,
          'verification.registeredTitle'.tr(),
          'verification.registeredBody'.tr(),
        ),
      VerificationStatus.underReview => (
          '⏳',
          AppColors.gold,
          'verification.underReviewTitle'.tr(),
          'verification.underReviewBody'.tr(),
        ),
      VerificationStatus.communityVerifiedProbation => (
          '🛡️',
          AppColors.teal,
          'verification.probationTitle'.tr(),
          'verification.probationBody'.tr(),
        ),
      VerificationStatus.communityVerified => (
          '✅',
          AppColors.teal,
          'verification.approvedTitle'.tr(),
          'verification.approvedBody'.tr(),
        ),
      VerificationStatus.trustedWorker => (
          '⭐',
          AppColors.gold,
          'verification.trustedTitle'.tr(),
          'verification.trustedBody'.tr(),
        ),
      VerificationStatus.suspended => (
          '⚠️',
          AppColors.danger,
          'verification.suspendedTitle'.tr(),
          'verification.suspendedBody'.tr(),
        ),
      VerificationStatus.revoked => (
          '🚫',
          AppColors.danger,
          'verification.revokedTitle'.tr(),
          'verification.revokedBody'.tr(),
        ),
      VerificationStatus.rejected => (
          '❌',
          AppColors.danger,
          'verification.rejectedTitle'.tr(),
          verification.reason ?? 'verification.rejectedBody'.tr(),
        ),
      VerificationStatus.unknown => (
          '🔍',
          AppColors.muted,
          'verification.checkingTitle'.tr(),
          'verification.checkingBody'.tr(),
        ),
    };

    return SkyScaffold(
      title: 'verification.title'.tr(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          children: [
            SkyCard(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 36)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Probation details card
            if (verification.status ==
                VerificationStatus.communityVerifiedProbation) ...[
              SkyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: AppColors.teal),
                        const SizedBox(width: 8),
                        const Text(
                          'Probation Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Active · Capped at ₹${verification.probationJobValueCap.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: verification.probationJobCountRequired > 0
                            ? (verification.probationJobCount /
                                    verification.probationJobCountRequired)
                                .clamp(0.0, 1.0)
                            : 0.0,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(AppColors.teal),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Completed Jobs: ${verification.probationJobCount} / ${verification.probationJobCountRequired}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          'Rating: ${verification.ratingAverage.toStringAsFixed(1)} ★ (Req: ${verification.probationMinRating.toStringAsFixed(1)})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Under review / References summary
            if (verification.status == VerificationStatus.underReview) ...[
              SkyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Review Checklist',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          verification.referencesCount >= 3
                              ? Icons.check_circle
                              : Icons.schedule,
                          color: verification.referencesCount >= 3
                              ? AppColors.teal
                              : AppColors.gold,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Community References: ${verification.verifiedReferencesCount} of ${verification.referencesCount} verified',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          verification.hasPracticalCheck
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: verification.hasPracticalCheck
                              ? AppColors.teal
                              : AppColors.muted,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          verification.hasPracticalCheck
                              ? (verification.practicalCheckPassed
                                  ? 'Practical Check: Passed'
                                  : 'Practical Check: Under Review')
                              : 'Practical Check: Not submitted / Not required',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Reason card for suspended or rejected
            if ((verification.status == VerificationStatus.rejected ||
                    verification.status == VerificationStatus.suspended) &&
                verification.reason != null) ...[
              SkyCard(
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.danger),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'verification.reasonLabel'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(verification.reason!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            if (verification.isJobEligible) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/dashboard'),
                  child: Text('verification.goToDashboard'.tr()),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (verification.status == VerificationStatus.rejected) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => setState(() => _showApplicationForm = true),
                  child: const Text('Re-apply for Verification'),
                ),
              ),
              const SizedBox(height: 12),
            ],

            OutlinedButton(
              onPressed: () => ref.read(verificationProvider.notifier).load(),
              child: Text('verification.refresh'.tr()),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              child: Text('profile.logout'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationApplicationForm extends ConsumerStatefulWidget {
  const _VerificationApplicationForm({required this.onSubmitted});

  final VoidCallback onSubmitted;

  @override
  ConsumerState<_VerificationApplicationForm> createState() =>
      _VerificationApplicationFormState();
}

class _VerificationApplicationFormState
    extends ConsumerState<_VerificationApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategoryId;
  int _yearsOfExperience = 3;
  String _learningMethod = 'Practical Experience / Self-Taught';
  final _experienceNotes = TextEditingController();
  final _practicalVideoUrl = TextEditingController();

  // 3 references
  final List<TextEditingController> _refNames = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final List<TextEditingController> _refPhones = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final List<String> _refRelationships = [
    'Previous Customer',
    'Contractor / Master Artisan',
    'Hardware / Trade Shopkeeper',
  ];

  bool _submitting = false;

  @override
  void dispose() {
    _experienceNotes.dispose();
    _practicalVideoUrl.dispose();
    for (final c in _refNames) {
      c.dispose();
    }
    for (final c in _refPhones) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final references = <Map<String, dynamic>>[];
    for (int i = 0; i < 3; i++) {
      if (_refNames[i].text.trim().isNotEmpty &&
          _refPhones[i].text.trim().isNotEmpty) {
        references.add({
          'name': _refNames[i].text.trim(),
          'phone': _refPhones[i].text.trim(),
          'relationship': _refRelationships[i],
          'yearsKnown': '2+ years',
          'workObserved': 'Direct trade work',
        });
      }
    }

    final evidences = <Map<String, dynamic>>[];
    if (_practicalVideoUrl.text.trim().isNotEmpty) {
      evidences.add({
        'evidenceType': 'PRACTICAL_CHECK',
        'title': 'Practical Trade Demonstration',
        'description': 'Submitted demonstration link / portfolio',
        'fileUrl': _practicalVideoUrl.text.trim(),
      });
    }

    final success = await ref
        .read(verificationProvider.notifier)
        .applyForVerification(
          primaryCategoryId: _selectedCategoryId,
          yearsOfExperience: _yearsOfExperience,
          learningMethod: _learningMethod,
          previousExperience: _experienceNotes.text.trim(),
          references: references,
          evidences: evidences,
        );

    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Application submitted successfully! An Area Officer will review your references.',
            ),
          ),
        );
        widget.onSubmitted();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit application. Please check inputs.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(servicesCatalogProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Community skill verification allows skilled artisans to work without formal certificates. Complete your profile below.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Trade Category
            const Text(
              'Primary Trade / Skill',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 8),
            catalogAsync.when(
              data: (categories) {
                if (_selectedCategoryId == null && categories.isNotEmpty) {
                  _selectedCategoryId = categories.first.id;
                }
                return DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => TextFormField(
                initialValue: 'Electrician / Plumber / Carpenter',
                decoration: const InputDecoration(
                  labelText: 'Primary Trade',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Years of Experience
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Years of Practical Experience',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  '$_yearsOfExperience years',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Slider(
              value: _yearsOfExperience.toDouble(),
              min: 1,
              max: 25,
              divisions: 24,
              onChanged: (val) =>
                  setState(() => _yearsOfExperience = val.toInt()),
            ),
            const SizedBox(height: 12),

            // Learning Method
            const Text(
              'How did you learn this trade?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _learningMethod,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Practical Experience / Self-Taught',
                  child: Text('Practical Experience / Self-Taught'),
                ),
                DropdownMenuItem(
                  value: 'Apprenticeship under Master Artisan',
                  child: Text('Apprenticeship under Master Artisan'),
                ),
                DropdownMenuItem(
                  value: 'Family Craft / Generational Trade',
                  child: Text('Family Craft / Generational Trade'),
                ),
                DropdownMenuItem(
                  value: 'Vocational Training / ITI',
                  child: Text('Vocational Training / ITI'),
                ),
              ],
              onChanged: (val) => setState(() => _learningMethod = val!),
            ),
            const SizedBox(height: 16),

            // Experience notes
            TextFormField(
              controller: _experienceNotes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Brief summary of past work & experience',
                hintText: 'e.g. 5 years wiring homes, installing distribution boards',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // 3 Community References
            Row(
              children: [
                const Text(
                  '3 Community References',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Required',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Our verification officer will place brief phone calls to verify your work.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 14),

            for (int i = 0; i < 3; i++) ...[
              SkyCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reference #${i + 1} (${_refRelationships[i]})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _refNames[i],
                      validator: (val) {
                        if (i < 2 && (val == null || val.trim().isEmpty)) {
                          return 'Please enter contact name';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Contact Name',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _refPhones[i],
                      keyboardType: TextInputType.phone,
                      validator: (val) {
                        if (i < 2 && (val == null || val.trim().length < 10)) {
                          return 'Enter valid 10-digit phone number';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            const SizedBox(height: 14),

            // Practical check link / demo
            const Text(
              'Practical Demonstration (Optional / High-Risk)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'High-risk trades (e.g. Electrical) require a short practical demonstration video or work photo link.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _practicalVideoUrl,
              decoration: const InputDecoration(
                labelText: 'Demonstration Video / Drive URL',
                hintText: 'https://youtube.com/... or Google Drive link',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(
                  _submitting
                      ? 'Submitting…'
                      : 'verification.submitCta'.tr(),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
