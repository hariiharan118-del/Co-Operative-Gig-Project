import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/visual_style.dart';
import '../../../core/widgets/photo_listing_card.dart';
import '../../../core/widgets/ui_kit.dart';
import '../domain/provider_models.dart';

class ProviderQueueScreen extends StatefulWidget {
  const ProviderQueueScreen({super.key});

  @override
  State<ProviderQueueScreen> createState() => _ProviderQueueScreenState();
}

class _ProviderQueueScreenState extends State<ProviderQueueScreen> {
  String _filter = 'All';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final items = mockProviders.where((item) {
      final matchesFilter = _filter == 'All' ||
          item.specialty.toLowerCase().contains(_filter.toLowerCase()) ||
          item.category.toLowerCase().contains(_filter.toLowerCase());
      final matchesQuery = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.specialty.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => context.pop(),
        ),
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
          Text(
            'providers.queueTitle'.tr(),
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'providers.queueSubtitle'.tr(),
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
              StatusChip(
                label: '${items.length} in queue',
                tone: AlertTone.info,
                emoji: '',
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'providers.searchHint'.tr(),
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final chip in const ['All', 'Electrician', 'Plumber', 'HVAC'])
                FilterChip(
                  selected: _filter == chip,
                  label: Text(chip),
                  selectedColor: AppColors.accent,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _filter == chip ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: AppColors.card,
                  side: BorderSide(
                    color: _filter == chip ? AppColors.accent : AppColors.primary,
                  ),
                  onSelected: (_) => setState(() => _filter = chip),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 308,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return PhotoListingCard(
                entranceIndex: index,
                title: item.name,
                subtitle: item.specialty,
                assetPath: categoryPhotoAssetPath(
                  name: '${item.specialty} ${item.category}',
                ),
                badgeLabel:
                    item.verified ? 'home.coopVerified'.tr() : null,
                showVerifiedBadge: item.verified,
                tags: item.skills,
                benefit: item.active ? 'Same-day visits' : 'Currently inactive',
                onTap: () => context.push('/providers/${item.id}'),
              );
            },
          ),
        ],
      ),
    );
  }
}
