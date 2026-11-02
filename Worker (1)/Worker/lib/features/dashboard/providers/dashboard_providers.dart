import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/socket_service.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/jobs_repository.dart';
import '../domain/nearby_job.dart';

final availabilityProvider =
    NotifierProvider<AvailabilityNotifier, bool>(AvailabilityNotifier.new);

class AvailabilityNotifier extends Notifier<bool> {
  @override
  bool build() {
    // TODO: GET /workers/me/availability
    return true;
  }

  Future<void> setOnline(bool online) async {
    // TODO: PATCH /workers/me/availability  body: { "online": online }
    // TODO: When going online, emit location on SocketService
    //       ('worker:location' with { lat, lng }).
    // TODO: When going offline, emit 'worker:offline'.
    state = online;
  }
}

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  return JobsRepository(ref.watch(apiClientProvider));
});

final nearbyJobsProvider =
    AsyncNotifierProvider<NearbyJobsNotifier, List<NearbyJob>>(
  NearbyJobsNotifier.new,
);

class NearbyJobsNotifier extends AsyncNotifier<List<NearbyJob>> {
  StreamSubscription<dynamic>? _broadcastSub;
  StreamSubscription<dynamic>? _removedSub;
  StreamSubscription<dynamic>? _statusSub;
  final Map<String, NearbyJob> _pendingAdds = {};
  final Set<String> _pendingRemoves = {};

  @override
  Future<List<NearbyJob>> build() async {
    _broadcastSub?.cancel();
    _removedSub?.cancel();
    _statusSub?.cancel();
    _broadcastSub =
        SocketService.instance.on('job:broadcast').listen(_onBroadcast);
    _removedSub = SocketService.instance.on('job:removed').listen(_onRemoved);
    _statusSub =
        SocketService.instance.on('booking:status_update').listen(_onStatus);
    ref.onDispose(() {
      _broadcastSub?.cancel();
      _removedSub?.cancel();
      _statusSub?.cancel();
    });

    final auth = ref.watch(authProvider);
    if (auth is! AuthAuthenticated) return const [];
    final token = auth.session.accessToken;
    if (token.isEmpty || token.startsWith('demo-')) return const [];
    final role = auth.session.user?.roleName ?? '';
    if (role == 'CUSTOMER') return const [];

    final jobs = await ref.read(jobsRepositoryProvider).listAvailable();
    final byId = {for (final job in jobs) job.id: job};
    byId.addAll(_pendingAdds);
    for (final id in _pendingRemoves) {
      byId.remove(id);
    }
    _pendingAdds.clear();
    _pendingRemoves.clear();
    return byId.values.toList();
  }

  Future<NearbyJob> accept(String bookingId) async {
    NearbyJob? previous;
    for (final job in state.valueOrNull ?? const <NearbyJob>[]) {
      if (job.id == bookingId) {
        previous = job;
        break;
      }
    }
    try {
      final accepted = await ref.read(jobsRepositoryProvider).accept(bookingId);
      _removeById(bookingId);
      return _withFeedFallback(accepted, previous);
    } on JobTakenException {
      _removeById(bookingId);
      rethrow;
    }
  }

  NearbyJob _withFeedFallback(NearbyJob accepted, NearbyJob? previous) {
    if (previous == null) return accepted;
    return NearbyJob(
      id: accepted.id.isEmpty ? previous.id : accepted.id,
      serviceType: accepted.serviceType == 'Job' || accepted.serviceType.isEmpty
          ? previous.serviceType
          : accepted.serviceType,
      distanceKm:
          accepted.distanceKm > 0 ? accepted.distanceKm : previous.distanceKm,
      estimatedPayPaise: accepted.estimatedPayPaise > 0
          ? accepted.estimatedPayPaise
          : previous.estimatedPayPaise,
      addressLine: accepted.addressLine.isNotEmpty
          ? accepted.addressLine
          : previous.addressLine,
      areaCode: accepted.areaCode,
      areaName: accepted.areaName == 'Bengaluru' && previous.areaName.isNotEmpty
          ? previous.areaName
          : accepted.areaName,
      lat: accepted.lat,
      lng: accepted.lng,
      customerName: accepted.customerName.isNotEmpty
          ? accepted.customerName
          : previous.customerName,
      customerPhone: accepted.customerPhone.isNotEmpty
          ? accepted.customerPhone
          : previous.customerPhone,
      notes: accepted.notes ?? previous.notes,
      isEmergency: accepted.isEmergency || previous.isEmergency,
    );
  }

  Future<void> decline(String id) async {
    _removeById(id);
  }

  void _onBroadcast(dynamic data) {
    final job = NearbyJob.tryParse(data);
    if (job == null) return;
    if (!state.hasValue) {
      _pendingAdds[job.id] = job;
      _pendingRemoves.remove(job.id);
      return;
    }
    _upsert(job);
  }

  void _onRemoved(dynamic data) {
    final id = bookingIdFromPayload(data);
    if (id == null) return;
    if (!state.hasValue) {
      _pendingRemoves.add(id);
      _pendingAdds.remove(id);
      return;
    }
    _removeById(id);
  }

  void _onStatus(dynamic data) {
    final id = bookingIdFromPayload(data);
    if (id == null) return;
    final map = data is Map ? Map<dynamic, dynamic>.from(data) : null;
    final status = '${map?['status'] ?? map?['bookingStatus'] ?? ''}'.toUpperCase();
    if (status == 'PENDING_MATCH' || status == 'BROADCASTING') return;
    if (status.isNotEmpty) _removeById(id);
  }

  void _upsert(NearbyJob job) {
    final current = [...(state.valueOrNull ?? const <NearbyJob>[])];
    final index = current.indexWhere((item) => item.id == job.id);
    if (index >= 0) {
      current[index] = job;
    } else {
      current.insert(0, job);
    }
    state = AsyncData(current);
  }

  void _removeById(String id) {
    final current = state.valueOrNull;
    if (current == null) {
      _pendingRemoves.add(id);
      _pendingAdds.remove(id);
      return;
    }
    state = AsyncData(current.where((job) => job.id != id).toList());
  }
}
