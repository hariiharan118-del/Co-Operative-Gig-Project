import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/history_repository.dart';
import '../data/mock_jobs.dart';
import '../domain/past_job.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(apiClientProvider));
});

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<PastJob>>(HistoryNotifier.new);

class HistoryNotifier extends AsyncNotifier<List<PastJob>> {
  @override
  Future<List<PastJob>> build() async {
    final auth = ref.watch(authProvider);
    if (auth is! AuthAuthenticated) return const [];
    if (auth.session.accessToken.startsWith('demo-')) return mockPastJobs;
    return ref.read(historyRepositoryProvider).listCompleted();
  }
}
