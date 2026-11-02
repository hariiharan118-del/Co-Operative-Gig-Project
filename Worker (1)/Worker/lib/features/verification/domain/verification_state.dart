enum VerificationStatus {
  unknown,
  registered,
  underReview,
  communityVerifiedProbation,
  communityVerified,
  trustedWorker,
  suspended,
  revoked,
  rejected,
}

class VerificationState {
  const VerificationState({
    required this.status,
    this.badgeState = 'ACTIVE',
    this.probationJobCount = 0,
    this.probationJobCountRequired = 5,
    this.probationMinRating = 4.0,
    this.probationJobValueCap = 1000.0,
    this.ratingAverage = 0.0,
    this.reviewCount = 0,
    this.jobEligible = false,
    this.eligibilityReason,
    this.badges = const [],
    this.referencesCount = 0,
    this.verifiedReferencesCount = 0,
    this.hasPracticalCheck = false,
    this.practicalCheckPassed = false,
    this.primaryTrade,
    this.isHighRisk = false,
    this.reason,
  });

  const VerificationState.unknown() : this(status: VerificationStatus.unknown);

  final VerificationStatus status;
  final String badgeState;
  final int probationJobCount;
  final int probationJobCountRequired;
  final double probationMinRating;
  final double probationJobValueCap;
  final double ratingAverage;
  final int reviewCount;
  final bool jobEligible;
  final String? eligibilityReason;
  final List<String> badges;
  final int referencesCount;
  final int verifiedReferencesCount;
  final bool hasPracticalCheck;
  final bool practicalCheckPassed;
  final String? primaryTrade;
  final bool isHighRisk;
  final String? reason;

  bool get isResolved => status != VerificationStatus.unknown;

  /// Worker can accept capped or full jobs
  bool get isJobEligible =>
      (status == VerificationStatus.communityVerifiedProbation ||
          status == VerificationStatus.communityVerified ||
          status == VerificationStatus.trustedWorker) &&
      badgeState == 'ACTIVE';

  /// Backwards-compatible alias for routers/screens checking isApproved
  bool get isApproved => isJobEligible;

  bool get isProbation =>
      status == VerificationStatus.communityVerifiedProbation;

  /// Ineligible workers are redirected to verification flow
  bool get isBlocked => !isJobEligible;

  VerificationState copyWith({
    VerificationStatus? status,
    String? badgeState,
    int? probationJobCount,
    int? probationJobCountRequired,
    double? probationMinRating,
    double? probationJobValueCap,
    double? ratingAverage,
    int? reviewCount,
    bool? jobEligible,
    String? eligibilityReason,
    List<String>? badges,
    int? referencesCount,
    int? verifiedReferencesCount,
    bool? hasPracticalCheck,
    bool? practicalCheckPassed,
    String? primaryTrade,
    bool? isHighRisk,
    String? reason,
    bool clearReason = false,
  }) {
    return VerificationState(
      status: status ?? this.status,
      badgeState: badgeState ?? this.badgeState,
      probationJobCount: probationJobCount ?? this.probationJobCount,
      probationJobCountRequired:
          probationJobCountRequired ?? this.probationJobCountRequired,
      probationMinRating: probationMinRating ?? this.probationMinRating,
      probationJobValueCap: probationJobValueCap ?? this.probationJobValueCap,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      reviewCount: reviewCount ?? this.reviewCount,
      jobEligible: jobEligible ?? this.jobEligible,
      eligibilityReason: eligibilityReason ?? this.eligibilityReason,
      badges: badges ?? this.badges,
      referencesCount: referencesCount ?? this.referencesCount,
      verifiedReferencesCount:
          verifiedReferencesCount ?? this.verifiedReferencesCount,
      hasPracticalCheck: hasPracticalCheck ?? this.hasPracticalCheck,
      practicalCheckPassed: practicalCheckPassed ?? this.practicalCheckPassed,
      primaryTrade: primaryTrade ?? this.primaryTrade,
      isHighRisk: isHighRisk ?? this.isHighRisk,
      reason: clearReason ? null : (reason ?? this.reason),
    );
  }

  factory VerificationState.fromJson(Map<String, dynamic> json) {
    final references = (json['references'] as List?) ?? const [];
    final evidences = (json['evidences'] as List?) ?? const [];
    final skills = (json['skills'] as List?) ?? const [];
    final badgeLabels = (json['badgeLabels'] as List?)?.cast<String>() ??
        (json['badges'] as List?)
            ?.map((b) => b is Map ? b['label']?.toString() ?? '' : b.toString())
            .where((s) => s.isNotEmpty)
            .toList() ??
        const <String>[];

    final primarySkill = skills.isNotEmpty && skills.first is Map
        ? skills.first as Map<String, dynamic>
        : null;

    return VerificationState(
      status: parseVerificationStatus(json['verificationStatus'] as String?),
      badgeState: json['badgeState']?.toString() ?? 'ACTIVE',
      probationJobCount: (json['probationJobCount'] as num?)?.toInt() ?? 0,
      probationJobCountRequired:
          (json['probationJobCountRequired'] as num?)?.toInt() ?? 5,
      probationMinRating:
          (json['probationMinRating'] as num?)?.toDouble() ?? 4.0,
      probationJobValueCap:
          (json['probationJobValueCap'] as num?)?.toDouble() ?? 1000.0,
      ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      jobEligible: json['jobEligible'] == true,
      eligibilityReason: json['eligibilityReason'] as String?,
      badges: badgeLabels,
      referencesCount: references.length,
      verifiedReferencesCount: references
          .where((r) => r is Map && r['status'] == 'VERIFIED')
          .length,
      hasPracticalCheck: evidences
          .any((e) => e is Map && e['evidenceType'] == 'PRACTICAL_CHECK'),
      practicalCheckPassed: skills.any(
          (s) => s is Map && s['practicalCheckPassed'] == true),
      primaryTrade: primarySkill?['categoryName'] as String?,
      isHighRisk: skills.any((s) => s is Map && s['riskTier'] == 'HIGH'),
      reason: json['verificationNote'] as String?,
    );
  }
}

VerificationStatus parseVerificationStatus(String? raw) {
  if (raw == null) return VerificationStatus.unknown;
  switch (raw.toUpperCase()) {
    case 'REGISTERED':
      return VerificationStatus.registered;
    case 'UNDER_REVIEW':
    case 'PENDING':
      return VerificationStatus.underReview;
    case 'COMMUNITY_VERIFIED_PROBATION':
      return VerificationStatus.communityVerifiedProbation;
    case 'COMMUNITY_VERIFIED':
    case 'APPROVED':
      return VerificationStatus.communityVerified;
    case 'TRUSTED_WORKER':
      return VerificationStatus.trustedWorker;
    case 'SUSPENDED':
      return VerificationStatus.suspended;
    case 'REVOKED':
      return VerificationStatus.revoked;
    case 'REJECTED':
      return VerificationStatus.rejected;
    default:
      return VerificationStatus.unknown;
  }
}
