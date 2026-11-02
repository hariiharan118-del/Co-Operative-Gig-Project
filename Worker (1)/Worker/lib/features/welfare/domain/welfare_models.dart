enum EnrollmentStatus { enrolled, pending, notEnrolled }

enum ClaimStatus { submitted, approved, rejected, paid }

class WelfareEnrollment {
  const WelfareEnrollment({
    required this.status,
    this.planName = 'KRIYANTA Partner Welfare Cover',
    this.coverageNote,
  });

  final EnrollmentStatus status;
  final String planName;
  final String? coverageNote;
}

class WelfareClaim {
  const WelfareClaim({
    required this.id,
    required this.category,
    required this.description,
    required this.status,
    required this.filedAt,
  });

  final String id;
  final String category;
  final String description;
  final ClaimStatus status;
  final DateTime filedAt;
}

class WelfareSnapshot {
  const WelfareSnapshot({
    required this.enrollment,
    required this.claims,
  });

  final WelfareEnrollment enrollment;
  final List<WelfareClaim> claims;

  WelfareSnapshot copyWith({
    WelfareEnrollment? enrollment,
    List<WelfareClaim>? claims,
  }) {
    return WelfareSnapshot(
      enrollment: enrollment ?? this.enrollment,
      claims: claims ?? this.claims,
    );
  }
}
