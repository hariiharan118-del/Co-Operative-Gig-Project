import '../../auth/domain/auth_state.dart';

enum CertificationStatus { pending, approved, rejected }

class Certification {
  const Certification({
    required this.id,
    required this.name,
    required this.status,
    this.rejectReason,
  });

  final String id;
  final String name;
  final CertificationStatus status;
  final String? rejectReason;

  factory Certification.fromJson(Map<String, dynamic> json) {
    final statusRaw = '${json['status'] ?? ''}'.toUpperCase();
    final status = switch (statusRaw) {
      'APPROVED' => CertificationStatus.approved,
      'REJECTED' => CertificationStatus.rejected,
      _ => CertificationStatus.pending,
    };
    final docUrl = '${json['docUrl'] ?? ''}';
    final name = json['name'] as String? ??
        (docUrl.isNotEmpty ? docUrl.split('/').last : 'Certificate');
    return Certification(
      id: '${json['id'] ?? ''}',
      name: name,
      status: status,
      rejectReason: json['adminNote'] as String?,
    );
  }
}

class WorkerSkillChoice {
  const WorkerSkillChoice({required this.categoryId, required this.name});

  final String categoryId;
  final String name;
}

class WorkerProfile {
  const WorkerProfile({
    this.userId = '',
    required this.name,
    required this.phone,
    this.skill = '',
    this.skills = const [],
    this.city = '',
    this.certifications = const [],
  });

  static const empty = WorkerProfile(name: '', phone: '');

  final String userId;
  final String name;
  final String phone;
  final String skill;
  final List<WorkerSkillChoice> skills;
  final String city;
  final List<Certification> certifications;

  factory WorkerProfile.fromAuthUser(AuthUser? user) {
    if (user == null) return WorkerProfile.empty;
    return WorkerProfile(
      userId: user.id,
      name: user.name ?? '',
      phone: user.phone,
      skill: user.skill ?? '',
      city: user.city ?? '',
    );
  }

  factory WorkerProfile.fromMeJson(Map<String, dynamic> json) {
    final user = AuthUser.fromJson(json);
    final worker = authJsonMap(json['workerProfile']);
    final rawCerts = worker?['certifications'];
    final certifications = <Certification>[];
    if (rawCerts is List) {
      for (final item in rawCerts) {
        final map = authJsonMap(item);
        if (map != null) certifications.add(Certification.fromJson(map));
      }
    }
    return WorkerProfile(
      userId: user.id,
      name: user.name ?? '',
      phone: user.phone,
      skill: user.skill ?? '',
      skills: parseWorkerSkills(worker),
      city: user.city ?? '',
      certifications: certifications,
    );
  }

  static List<WorkerSkillChoice> parseWorkerSkills(Map<String, dynamic>? worker) {
    if (worker == null) return const [];
    final raw = worker['skills'];
    if (raw is! List) return const [];
    final out = <WorkerSkillChoice>[];
    for (final item in raw) {
      final map = authJsonMap(item);
      if (map == null) continue;
      final category = authJsonMap(map['category']);
      final id = '${category?['id'] ?? map['categoryId'] ?? ''}';
      if (id.isEmpty) continue;
      out.add(
        WorkerSkillChoice(
          categoryId: id,
          name: '${category?['name'] ?? map['name'] ?? ''}',
        ),
      );
    }
    return out;
  }

  WorkerProfile copyWith({
    String? userId,
    String? name,
    String? phone,
    String? skill,
    List<WorkerSkillChoice>? skills,
    String? city,
    List<Certification>? certifications,
  }) {
    return WorkerProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      skill: skill ?? this.skill,
      skills: skills ?? this.skills,
      city: city ?? this.city,
      certifications: certifications ?? this.certifications,
    );
  }
}
