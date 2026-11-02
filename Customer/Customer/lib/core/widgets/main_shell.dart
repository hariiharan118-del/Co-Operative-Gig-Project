import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/booking/providers/live_bookings_provider.dart';
import '../../features/support/presentation/support_chat_screen.dart';
import '../theme.dart';

class MainShell extends ConsumerWidget {
  const MainShell({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  static const _tabs = ['/home', '/history', '/profile'];

  int get _index {
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    context.go(_tabs[index]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(liveBookingsProvider);
    return Scaffold(
      body: Stack(
        children: [
          child,
          Positioned(
            right: 16,
            bottom: 16,
            child: Material(
              color: AppColors.card,
              shape: const CircleBorder(),
              elevation: 0,
              child: InkWell(
                onTap: () => showSupportChatOverlay(context),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => _onTap(context, index),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home),
              selectedIcon: const Icon(Icons.home),
              label: 'nav.home'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long),
              selectedIcon: const Icon(Icons.receipt_long),
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
