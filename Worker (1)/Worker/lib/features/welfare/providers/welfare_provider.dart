import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/socket_service.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/welfare_repository.dart';
import '../domain/welfare_models.dart';

const claimCategories = [
  'Injury on job',
  'Tool damage',
  'Medical',
  'Income support',
  'Other',
];

final welfareProvider =
    NotifierProvider<WelfareNotifier, WelfareSnapshot>(WelfareNotifier.new);

final welfareRepositoryProvider = Provider<WelfareRepository>((ref) {
  return WelfareRepository(ref.watch(apiClientProvider));
});

class WelfareNotifier extends Notifier<WelfareSnapshot> {
  StreamSubscription<dynamic>? _claimUpdates;

  @override
  WelfareSnapshot build() {
    final auth = ref.watch(authProvider);
    _claimUpdates ??= SocketService.instance
        .on('welfare:claim_update')
        .listen(_applySocketUpdate);
    ref.onDispose(() => _claimUpdates?.cancel());

    if (auth is AuthAuthenticated &&
        !auth.session.accessToken.startsWith('demo-')) {
      Future.microtask(refresh);
    }

    return const WelfareSnapshot(
      enrollment: WelfareEnrollment(status: EnrollmentStatus.notEnrolled),
      claims: [],
    );
  }

  Future<void> refresh() async {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated ||
        auth.session.accessToken.startsWith('demo-')) {
      return;
    }
    state = await ref.read(welfareRepositoryProvider).getMine();
  }

  Future<void> fileClaim({
    required String category,
    required String description,
  }) async {
    final claim = await ref.read(welfareRepositoryProvider).createClaim(
          category: category,
          description: description,
        );
    _upsertClaim(claim);
  }

  void _applySocketUpdate(dynamic raw) {
    if (raw is! Map) return;
    _upsertClaim(
      welfareClaimFromJson(Map<String, dynamic>.from(raw)),
    );
  }

  void _upsertClaim(WelfareClaim claim) {
    final claims = [
      claim,
      for (final existing in state.claims)
        if (existing.id != claim.id) existing,
    ]..sort((a, b) => b.filedAt.compareTo(a.filedAt));
    state = state.copyWith(claims: claims);
  }
}
