import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/providers/dashboard_providers.dart';
import '../../features/job/providers/active_job_provider.dart';
import '../theme.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(nearbyJobsProvider);
    ref.watch(activeJobProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onTap,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.work),
              selectedIcon: const Icon(Icons.work),
              label: 'nav.dashboard'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet),
              selectedIcon: const Icon(Icons.account_balance_wallet),
              label: 'nav.earnings'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.history),
              selectedIcon: const Icon(Icons.history),
              label: 'nav.history'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person),
              selectedIcon: const Icon(Icons.person),
              label: 'nav.profile'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}
