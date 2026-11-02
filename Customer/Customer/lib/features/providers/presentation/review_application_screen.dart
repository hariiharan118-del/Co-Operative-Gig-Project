import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/visual_style.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/ui_kit.dart';
import '../domain/provider_models.dart';
import 'approve_provider_dialog.dart';

class ReviewApplicationScreen extends StatelessWidget {
  const ReviewApplicationScreen({super.key, required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context) {
    final item = providerById(providerId);
    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Provider not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('providers.reviewTitle'.tr())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          AppCard(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: avatarColorFor(item.name),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        item.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 28,
                        ),
                      ),
                    ),
                    const StatusChip(
                      label: 'Pending',
                      tone: AlertTone.warning,
                      icon: Icons.schedule,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  item.name,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(item.category, style: const TextStyle(color: AppColors.muted)),
                Text(
                  'Submitted: ${item.submittedLabel}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel('providers.about'.tr()),
                const SizedBox(height: 8),
                Text(item.about, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel('providers.skills'.tr()),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final skill in item.skills)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SectionLabel('providers.documents'.tr()),
                ),
                _DocTile(icon: Icons.badge_outlined, name: 'State License.pdf', size: '2.4 MB'),
                const Divider(height: 1),
                _DocTile(icon: Icons.verified_user_outlined, name: 'ID Proof.pdf', size: '1.1 MB'),
                const Divider(height: 1),
                _DocTile(icon: Icons.assignment_outlined, name: 'Insurance.pdf', size: '890 KB'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PressScale(
            child: FilledButton(
              onPressed: () => showApproveProviderDialog(context, item),
              child: Text('providers.approve'.tr()),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.push('/providers/${item.id}/profile'),
            child: Text('providers.viewProfile'.tr()),
          ),
        ],
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({required this.icon, required this.name, required this.size});

  final IconData icon;
  final String name;
  final String size;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconTile(icon: icon),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(size),
      trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
    );
  }
}
