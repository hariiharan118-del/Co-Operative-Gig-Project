import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/ui_kit.dart';

class ServiceRegionScreen extends StatefulWidget {
  const ServiceRegionScreen({super.key});

  @override
  State<ServiceRegionScreen> createState() => _ServiceRegionScreenState();
}

class _ServiceRegionScreenState extends State<ServiceRegionScreen> {
  bool _allowed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('providers.registration'.tr()),
        actions: [
          TextButton(
            onPressed: () => context.push('/providers'),
            child: Text('providers.portal'.tr()),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            Row(
              children: List.generate(4, (index) {
                final filled = index < 3;
                return Expanded(
                  child: Container(
                    height: 6,
                    margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                    decoration: BoxDecoration(
                      color: filled ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'providers.regionTitle'.tr(),
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'providers.regionBody'.tr(),
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const Spacer(),
            AppCard(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.location_on, color: AppColors.primary, size: 34),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _allowed
                        ? 'Location access granted for Bengaluru.'
                        : 'providers.regionCard'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            PressScale(
              child: FilledButton.icon(
                onPressed: () => setState(() => _allowed = true),
                icon: const Icon(Icons.send),
                label: Text('providers.allowLocation'.tr()),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: Text('common.back'.tr()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PressScale(
                    enabled: _allowed,
                    child: FilledButton(
                      onPressed: _allowed ? () => context.pop() : null,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            _allowed ? AppColors.primary : AppColors.muted,
                      ),
                      child: Text('common.next'.tr()),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
