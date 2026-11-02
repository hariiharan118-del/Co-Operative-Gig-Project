class NearbyProvider {
  const NearbyProvider({
    required this.id,
    required this.name,
    this.photoUrl,
    this.specialty,
    this.categoryId,
    this.categorySlug,
    this.ratingAverage,
    this.startingPricePaise,
    this.tags = const [],
    this.locationLabel,
    this.benefit,
    this.verified = true,
    this.badges = const [],
    this.isProbation = false,
    this.isTrusted = false,
    this.isCertificateVerified = false,
    this.verificationStatus,
  });

  final String id;
  final String name;
  final String? photoUrl;
  final String? specialty;
  final String? categoryId;
  final String? categorySlug;
  final double? ratingAverage;
  final int? startingPricePaise;
  final List<String> tags;
  final String? locationLabel;
  final String? benefit;
  final bool verified;
  final List<String> badges;
  final bool isProbation;
  final bool isTrusted;
  final bool isCertificateVerified;
  final String? verificationStatus;

  /// Primary badge label to show prominently on cards
  String get primaryTrustBadge {
    if (isTrusted) return 'Trusted Worker';
    if (isProbation) return 'Community Verified — Probation';
    if (badges.any((b) => b.contains('Community Verified'))) {
      return 'Community Verified';
    }
    if (verified) return 'Community Verified';
    return 'Identity Verified';
  }
}
