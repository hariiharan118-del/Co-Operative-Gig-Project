import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../../../core/api_error.dart';
import '../domain/welfare_models.dart';

class WelfareRepository {
  WelfareRepository(this._api);

  final ApiClient _api;

  Future<WelfareSnapshot> getMine() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('/welfare/me');
      return welfareSnapshotFromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw Exception(describeApiError(error));
    }
  }

  Future<WelfareClaim> createClaim({
    required String category,
    required String description,
  }) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/welfare/claims',
        data: {
          'category': category.trim(),
          'description': description.trim(),
        },
      );
      return welfareClaimFromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw Exception(describeApiError(error));
    }
  }
}

WelfareSnapshot welfareSnapshotFromJson(Map<String, dynamic> json) {
  final rawClaims = json['claims'];
  final claims = <WelfareClaim>[
    if (rawClaims is List)
      for (final raw in rawClaims)
        if (raw is Map)
          welfareClaimFromJson(Map<String, dynamic>.from(raw)),
  ];
  claims.sort((a, b) => b.filedAt.compareTo(a.filedAt));

  return WelfareSnapshot(
    enrollment: WelfareEnrollment(
      status: enrollmentStatusFromApi(json['enrollmentStatus']),
      coverageNote: json['coverageNote']?.toString(),
    ),
    claims: claims,
  );
}

WelfareClaim welfareClaimFromJson(Map<String, dynamic> json) {
  return WelfareClaim(
    id: '${json['id'] ?? ''}',
    category: '${json['category'] ?? ''}',
    description: '${json['description'] ?? ''}',
    status: claimStatusFromApi(json['status']),
    filedAt: DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
  );
}

EnrollmentStatus enrollmentStatusFromApi(dynamic raw) {
  return switch ('${raw ?? ''}'.toUpperCase()) {
    'ENROLLED' => EnrollmentStatus.enrolled,
    'SUSPENDED' => EnrollmentStatus.pending,
    _ => EnrollmentStatus.notEnrolled,
  };
}

ClaimStatus claimStatusFromApi(dynamic raw) {
  return switch ('${raw ?? ''}'.toUpperCase()) {
    'APPROVED' => ClaimStatus.approved,
    'REJECTED' => ClaimStatus.rejected,
    'PAID' => ClaimStatus.paid,
    _ => ClaimStatus.submitted,
  };
}
