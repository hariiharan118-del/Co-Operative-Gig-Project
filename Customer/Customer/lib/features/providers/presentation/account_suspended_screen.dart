import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/ui_kit.dart';

class AccountSuspendedScreen extends StatelessWidget {
  const AccountSuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KRIYANTA'),
        actions: const [
          Icon(Icons.notifications_none_outlined),
          SizedBox(width: 8),
          Icon(Icons.settings_outlined),
          SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          AlertBanner(
            title: 'providers.suspendedTitle'.tr(),
            body: 'providers.suspendedBody'.tr(),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'providers.requiredAction'.tr(),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'providers.requiredActionBody'.tr(),
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 14),
                PressScale(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: Text('providers.reactivate'.tr()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionLabel('providers.suspensionLog'.tr()),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _LogTile(
                  icon: Icons.block,
                  title: 'Account Suspended',
                  date: 'Oct 24, 2023',
                  body: 'System automated suspension trigger based on SLA metrics.',
                ),
                const Divider(height: 1),
                _LogTile(
                  icon: Icons.warning_amber_rounded,
                  title: 'Unfulfilled requests',
                  date: 'Oct 22, 2023',
                  body: 'Two accepted jobs were not started within the promised window.',
                ),
                const Divider(height: 1),
                _LogTile(
                  icon: Icons.info_outline,
                  title: 'Warning issued',
                  date: 'Oct 18, 2023',
                  body: 'First notice sent to the provider dashboard.',
                  shaded: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({
    required this.icon,
    required this.title,
    required this.date,
    required this.body,
    this.shaded = false,
  });

  final IconData icon;
  final String title;
  final String date;
  final String body;
  final bool shaded;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: shaded ? const Color(0xFFF3F5F9) : Colors.transparent,
      child: ListTile(
        leading: IconTile(icon: icon),
        title: Row(
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text(date, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
        subtitle: Text(body),
      ),
    );
  }
}
