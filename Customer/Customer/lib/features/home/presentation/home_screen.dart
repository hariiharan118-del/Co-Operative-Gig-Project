import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/visual_style.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/photo_listing_card.dart';
import '../../../core/widgets/shimmer_skeletons.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../booking/presentation/active_booking_card.dart';
import '../../booking/providers/booking_providers.dart';
import '../../history/data/mock_bookings.dart';
import '../domain/nearby_provider.dart';
import '../domain/service_category.dart';
import '../providers/home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final providersAsync = ref.watch(nearbyProvidersProvider);
    final location = ref.watch(homeLocationProvider);
    final hideLocationHint = ref.watch(locationHintDismissedProvider);
    final showLocationHint = !hideLocationHint &&
        (location.valueOrNull?.denied ?? false);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    const BrandMark(size: 36),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'KRIYANTA',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none_outlined),
                    ),
                    IconButton(
                      onPressed: () => context.go('/profile'),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'home.greeting'.tr(),
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'home.subtitle'.tr(),
                      style: const TextStyle(color: AppColors.muted, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => context.push('/providers'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.fieldFill,
                          borderRadius: BorderRadius.circular(AppRadii.field),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppColors.muted, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'providers.searchHint'.tr(),
                                style: const TextStyle(color: AppColors.muted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    PressScale(
                      child: FilledButton(
                        onPressed: () => context.push('/providers'),
                        child: Text('providers.queueTitle'.tr()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: ActiveBookingBanner()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'home.categoriesTitle'.tr(),
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          ...categoriesAsync.when(
            loading: () => [
              const ListingGridSkeletonSliver(),
            ],
            error: (error, _) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(error.toString()),
                ),
              ),
            ],
            data: (categories) {
              final items = categories.isEmpty ? mockCategories : categories;
              return [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 208,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final category = items[index];
                        return PhotoListingCard(
                          entranceIndex: index,
                          title: category.name,
                          assetPath: categoryPhotoAssetPath(
                            slug: category.slug,
                            name: category.name,
                          ),
                          badgeLabel: 'home.fromPrice'.tr(
                            args: [formatPaise(category.basePricePaise)],
                          ),
                          onTap: () {
                            ref
                                .read(bookingDraftProvider.notifier)
                                .startWith(category);
                            context.push('/booking/address');
                          },
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
              ];
            },
          ),
          if (showLocationHint)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _LocationHintBanner(
                  onDismiss: () {
                    ref.read(locationHintDismissedProvider.notifier).state =
                        true;
                  },
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, showLocationHint ? 16 : 28, 20, 12),
              child: Text(
                'home.topRatedTitle'.tr(),
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          ...providersAsync.when(
            loading: () => [
              const ListingGridSkeletonSliver(
                tall: true,
                bottomPadding: 88,
              ),
            ],
            error: (error, _) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
                  child: Text(error.toString()),
                ),
              ),
            ],
            data: (providers) {
              if (providers.isEmpty) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
                      child: InvitationEmpty(
                        emoji: '👷',
                        message: 'home.topRatedEmpty'.tr(),
                      ),
                    ),
                  ),
                ];
              }
              return [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 308,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final provider = providers[index];
                        return PhotoListingCard(
                          entranceIndex: index,
                          title: provider.name,
                          subtitle: provider.specialty,
                          photoUrl: provider.photoUrl,
                          assetPath: categoryPhotoAssetPath(
                            slug: provider.categorySlug,
                            name: provider.specialty ?? provider.name,
                          ),
                          badgeLabel: provider.primaryTrustBadge,
                          showVerifiedBadge: provider.verified,
                          rating: provider.ratingAverage,
                          tags: provider.tags,
                          locationLabel: provider.locationLabel,
                          benefit: provider.benefit,
                          onTap: () =>
                              _bookWithProvider(ref, context, provider),
                        );
                      },
                      childCount: providers.length,
                    ),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  void _bookWithProvider(
    WidgetRef ref,
    BuildContext context,
    NearbyProvider provider,
  ) {
    final categories =
        ref.read(serviceCategoriesProvider).valueOrNull ?? mockCategories;
    ServiceCategory? match;
    for (final category in categories) {
      if (provider.categoryId != null && category.id == provider.categoryId) {
        match = category;
        break;
      }
    }
    match ??= () {
      final specialty = (provider.specialty ?? '').toLowerCase();
      for (final category in categories) {
        if (specialty.contains(category.name.toLowerCase()) ||
            category.name.toLowerCase().contains(specialty.split(' ').first)) {
          return category;
        }
      }
      return categories.isEmpty ? null : categories.first;
    }();
    if (match == null) return;
    ref.read(bookingDraftProvider.notifier).startWith(
          ServiceCategory(
            id: match.id,
            name: match.name,
            slug: match.slug,
            iconName: match.iconName,
            basePricePaise: provider.startingPricePaise ?? match.basePricePaise,
          ),
        );
    context.push('/booking/address');
  }
}

class _LocationHintBanner extends StatelessWidget {
  const _LocationHintBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warningSoft,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 20,
              color: AppColors.warning,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'home.locationHintTitle'.tr(),
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'home.locationHintBody'.tr(),
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              tooltip: 'common.close'.tr(),
              icon: const Icon(Icons.close, size: 18, color: AppColors.warning),
            ),
          ],
        ),
      ),
    );
  }
}
