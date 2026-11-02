import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/services_catalog.dart';
import '../domain/profile_models.dart';

const _demoProfile = WorkerProfile(
  userId: 'demo-worker',
  name: 'Ramesh K',
  phone: '+91 98765 43210',
  skill: 'Electrician',
  skills: [
    WorkerSkillChoice(categoryId: 'demo-electrician', name: 'Electrician'),
  ],
  city: 'Bengaluru, Karnataka',
  certifications: [
    Certification(
      id: 'cert_1',
      name: 'Trade certificate — Electrician',
      status: CertificationStatus.approved,
    ),
    Certification(
      id: 'cert_2',
      name: 'Police verification',
      status: CertificationStatus.pending,
    ),
    Certification(
      id: 'cert_3',
      name: 'First-aid training',
      status: CertificationStatus.rejected,
      rejectReason: 'Document photo is cropped. Please re-upload.',
    ),
  ],
);

String _sessionKey(AuthState auth) {
  if (auth is AuthAuthenticated) {
    return [
      auth.session.accessToken,
      auth.session.user?.id ?? '',
      auth.session.user?.phone ?? '',
    ].join('|');
  }
  return auth.runtimeType.toString();
}

final profileProvider =
    NotifierProvider<ProfileNotifier, WorkerProfile>(ProfileNotifier.new);

final servicesCatalogProvider =
    FutureProvider<List<ServiceCategoryOption>>((ref) {
  return ServicesCatalog(ref.watch(apiClientProvider)).list();
});

class ProfileNotifier extends Notifier<WorkerProfile> {
  int _loadGeneration = 0;

  @override
  WorkerProfile build() {
    ref.watch(authProvider.select(_sessionKey));
    final auth = ref.read(authProvider);
    if (auth is AuthAuthenticated &&
        auth.session.accessToken.startsWith('demo-')) {
      return _demoProfile;
    }
    if (auth is! AuthAuthenticated) {
      _loadGeneration++;
      return WorkerProfile.empty;
    }
    unawaited(refresh());
    return WorkerProfile.fromAuthUser(auth.session.user);
  }

  Future<void> refresh() async {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) {
      state = WorkerProfile.empty;
      return;
    }
    if (auth.session.accessToken.startsWith('demo-')) {
      state = _demoProfile;
      return;
    }
    final generation = ++_loadGeneration;
    final token = auth.session.accessToken;
    try {
      final json = await ref.read(authRepositoryProvider).getMeJson();
      if (generation != _loadGeneration) return;
      final current = ref.read(authProvider);
      if (current is! AuthAuthenticated ||
          current.session.accessToken != token) {
        return;
      }
      state = WorkerProfile.fromMeJson(json);
      ref.read(authProvider.notifier).syncUser(AuthUser.fromJson(json));
    } catch (_) {
      if (generation != _loadGeneration) return;
      final current = ref.read(authProvider);
      if (current is! AuthAuthenticated ||
          current.session.accessToken != token) {
        state = WorkerProfile.empty;
      }
    }
  }

  Future<void> save({
    required String name,
    required String city,
    String? stateName,
    required Set<String> selectedSkillIds,
  }) async {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;
    if (auth.session.accessToken.startsWith('demo-')) {
      final catalog = await ref.read(servicesCatalogProvider.future);
      final byId = {for (final item in catalog) item.id: item.name};
      state = state.copyWith(
        name: name,
        city: stateName == null || stateName.isEmpty
            ? city
            : '$city, $stateName',
        skill: selectedSkillIds.isEmpty
            ? ''
            : (byId[selectedSkillIds.first] ?? state.skill),
        skills: [
          for (final id in selectedSkillIds)
            WorkerSkillChoice(
              categoryId: id,
              name: byId[id] ?? id,
            ),
        ],
      );
      return;
    }

    final repo = ref.read(authRepositoryProvider);
    await repo.saveWorkerProfile(
      name: name,
      city: city,
      state: stateName,
    );

    final previous = {for (final skill in state.skills) skill.categoryId};
    final toAdd = selectedSkillIds.difference(previous);
    final toRemove = previous.difference(selectedSkillIds);
    await Future.wait([
      for (final id in toAdd) repo.addWorkerSkill(id),
      for (final id in toRemove) repo.removeWorkerSkill(id),
    ]);
    await refresh();
  }

  Future<void> uploadCertification(String name) async {
    // TODO: POST /users/worker/me/certifications  (multipart file + display name)
    final cert = Certification(
      id: 'cert_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      status: CertificationStatus.pending,
    );
    state = state.copyWith(certifications: [cert, ...state.certifications]);
  }
}
