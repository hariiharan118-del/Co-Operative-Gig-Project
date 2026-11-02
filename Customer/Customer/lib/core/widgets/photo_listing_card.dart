import 'package:flutter/material.dart';

import '../theme.dart';
import 'motion.dart';

const listingPlaceholder = AppColors.splash;
const listingBadge = AppColors.primary;

/// Marketplace photo card used for both service categories and providers.
class PhotoListingCard extends StatefulWidget {
  const PhotoListingCard({
    super.key,
    required this.title,
    required this.onTap,
    this.photoUrl,
    this.assetPath,
    this.badgeLabel,
    this.showVerifiedBadge = false,
    this.subtitle,
    this.rating,
    this.tags = const [],
    this.locationLabel,
    this.benefit,
    this.entranceIndex,
  });

  final String title;
  final VoidCallback onTap;
  final String? photoUrl;
  final String? assetPath;
  final String? badgeLabel;
  final bool showVerifiedBadge;
  final String? subtitle;
  final double? rating;
  final List<String> tags;
  final String? locationLabel;
  final String? benefit;
  final int? entranceIndex;

  @override
  State<PhotoListingCard> createState() => _PhotoListingCardState();
}

class _PhotoListingCardState extends State<PhotoListingCard> {
  bool _favorite = false;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: const BorderSide(color: AppColors.border),
    );

    final card = Material(
      color: AppColors.card,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        customBorder: shape,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PhotoHeader(
              photoUrl: widget.photoUrl,
              assetPath: widget.assetPath,
              badgeLabel: widget.badgeLabel,
              showVerifiedBadge: widget.showVerifiedBadge,
              favorite: _favorite,
              onFavorite: () => setState(() => _favorite = !_favorite),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                  if (widget.subtitle != null &&
                      widget.subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (widget.rating != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.tags.take(3).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (widget.locationLabel != null &&
                      widget.locationLabel!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: listingBadge,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.locationLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.benefit != null &&
                      widget.benefit!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: listingPlaceholder,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        widget.benefit!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: listingBadge,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );

    return StaggeredFadeSlide(
      index: widget.entranceIndex ?? 0,
      child: card,
    );
  }
}

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({
    required this.favorite,
    required this.onFavorite,
    this.photoUrl,
    this.assetPath,
    this.badgeLabel,
    this.showVerifiedBadge = false,
  });

  final String? photoUrl;
  final String? assetPath;
  final String? badgeLabel;
  final bool showVerifiedBadge;
  final bool favorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ListingPhoto(photoUrl: photoUrl, assetPath: assetPath),
          if (badgeLabel != null && badgeLabel!.trim().isNotEmpty)
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: listingBadge,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showVerifiedBadge) ...[
                      const Icon(
                        Icons.verified_user,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      badgeLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onFavorite,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(
                    favorite ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: listingBadge,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingPhoto extends StatelessWidget {
  const _ListingPhoto({this.photoUrl, this.assetPath});

  final String? photoUrl;
  final String? assetPath;

  static const _placeholder = ColoredBox(color: listingPlaceholder);

  @override
  Widget build(BuildContext context) {
    final network = photoUrl?.trim();
    if (network != null && network.isNotEmpty) {
      return Image.network(
        network,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _assetOrPlaceholder(),
      );
    }
    return _assetOrPlaceholder();
  }

  Widget _assetOrPlaceholder() {
    final asset = assetPath?.trim();
    if (asset == null || asset.isEmpty) return _placeholder;
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder,
    );
  }
}
