import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/visual_style.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/ui_kit.dart';
import '../domain/provider_models.dart';
import 'deactivate_account_sheet.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key, required this.providerId});

  final String providerId;

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  bool _accepting = true;
  bool _skillsOpen = true;

  @override
  Widget build(BuildContext context) {
    final item = providerById(widget.providerId);
    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Provider not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('providers.profileTitle'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => showDeactivateAccountSheet(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Center(
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: avatarColorFor(item.name),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    item.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (item.verified)
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.success,
                      child: Icon(Icons.verified, size: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${item.specialty} • ID: ${item.license}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Center(
            child: SuccessChip(
              label: item.active ? 'Active Provider' : 'Inactive',
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_outlined, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Trust & Verification',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'Community Verified',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Skills verified through community references and practical experience, evaluated by an Area Verification Officer.',
                        style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 15, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Identity Verified · Active Cooperative Member',
                      style: TextStyle(fontSize: 12, color: AppColors.navy),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(() => _skillsOpen = !_skillsOpen),
                  child: Row(
                    children: [
                      const Icon(Icons.handyman_outlined, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'providers.skillsTitle'.tr(),
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        _skillsOpen ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ),
                if (_skillsOpen) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final skill in item.skills)
                        Chip(
                          avatar: Text(ServiceLooks.of(skill).emoji),
                          label: Text(skill),
                          backgroundColor: ServiceLooks.of(skill).soft,
                          side: BorderSide.none,
                          labelStyle: TextStyle(
                            color: ServiceLooks.of(skill).color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'providers.listing'.tr(),
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'TOTAL EARNINGS',
                        value: item.earningsLabel,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        label: 'COMPLETED JOBS',
                        value: '${item.jobsCompleted}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.event_available_outlined, color: AppColors.primary),
              title: Text('providers.availability'.tr()),
              subtitle: Text(
                _accepting
                    ? 'Currently accepting new jobs'
                    : 'Not accepting jobs',
              ),
              value: _accepting,
              activeColor: AppColors.primary,
              onChanged: (value) => setState(() => _accepting = value),
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => context.push('/history'),
            child: const Row(
              children: [
                Icon(Icons.history, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service History',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'View past jobs, ratings, and client feedback.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: Text('common.edit'.tr()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PressScale(
                  child: FilledButton(
                    onPressed: () => context.push('/account/suspended'),
                    child: Text('providers.manageStatus'.tr()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.link,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
