import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/maps_launcher.dart';
import '../../../core/socket_service.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../history/providers/history_provider.dart';
import '../domain/active_job.dart';

final activeJobProvider =
    NotifierProvider<ActiveJobNotifier, ActiveJob?>(ActiveJobNotifier.new);

class ActiveJobNotifier extends Notifier<ActiveJob?> {
  StreamSubscription<dynamic>? _statusSub;
  String? _joinedBookingId;
  Timer? _awaitingPaymentPoll;

  static const _awaitingPaymentPollInterval = Duration(seconds: 2);

  @override
  ActiveJob? build() {
    ref.onDispose(() {
      _statusSub?.cancel();
      _awaitingPaymentPoll?.cancel();
      _leaveJoined();
    });

    _statusSub ??=
        SocketService.instance.on('booking:status_update').listen(_onStatusUpdate);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is! AuthAuthenticated) {
        _setJob(null);
        return;
      }
      unawaited(restoreCurrent());
    }, fireImmediately: true);
    return null;
  }

  void start(ActiveJob job) {
    _setJob(job.status.isOpen ? job : null);
  }

  void clear() {
    _setJob(null);
  }

  Future<void> restoreCurrent() async {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;
    if (auth.session.accessToken.startsWith('demo-')) return;

    try {
      final remote = await ref.read(jobsRepositoryProvider).findActive();
      if (ref.read(authProvider) is! AuthAuthenticated) return;
      _applyRemote(remote);
    } catch (_) {
      // Keep the in-session job if the bookings list is unavailable.
    }
  }

  Future<void> ensure(String jobId, {bool forceRefresh = false}) async {
    final current = state;
    if (!forceRefresh &&
        current != null &&
        current.id == jobId &&
        current.status.isOpen) {
      _syncRoom(current.id, force: true);
      return;
    }

    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated ||
        auth.session.accessToken.startsWith('demo-')) {
      return;
    }

    try {
      final remote = await ref.read(jobsRepositoryProvider).getBooking(jobId);
      if (remote == null) {
        final current = state;
        if (current != null && current.id == jobId && current.status.isOpen) {
          _syncRoom(current.id, force: true);
          return;
        }
        if (state?.id == jobId) _setJob(null);
        return;
      }
      _applyRemote(remote);
    } catch (_) {
      // Leave the in-session job if this booking cannot be fetched.
    }
  }

  void _applyRemote(ActiveJob? remote) {
    if (remote == null) return;
    if (!remote.status.isOpen && remote.status != JobLifecycleStatus.completed) {
      if (state != null && !state!.status.isOpen) {
        _setJob(null);
      }
      return;
    }

    final local = state;
    if (local != null &&
        local.id == remote.id &&
        local.status.progressRank > remote.status.progressRank) {
      _syncRoom(local.id);
      return;
    }
    _setJob(remote);
  }

  void _onStatusUpdate(dynamic raw) {
    final map = _asMap(raw);
    if (map == null) return;
    final bookingId = '${map['bookingId'] ?? map['booking_id'] ?? ''}';
    final current = state;
    if (bookingId.isEmpty || current == null || current.id != bookingId) {
      return;
    }

    final rawStatus = map['status'] ?? map['bookingStatus'];
    final statusLabel = '${rawStatus ?? ''}'.toUpperCase();
    if (statusLabel.isEmpty) return;
    if (statusLabel == 'COMPLETED') {
      _setJob(current.copyWith(status: JobLifecycleStatus.completed));
      return;
    }
    if (statusLabel == 'AWAITING_PAYMENT' || statusLabel == 'AWAITINGPAYMENT') {
      _setJob(current.copyWith(status: JobLifecycleStatus.awaitingPayment));
      return;
    }
    final closed = statusLabel == 'CANCELLED' ||
        statusLabel == 'CANCELED' ||
        statusLabel == 'EXPIRED';
    if (closed) {
      _setJob(null);
      return;
    }
    final status = jobLifecycleFromApi(rawStatus);
    if (status == null) return;
    final eta = _etaMinutes(map['etaMinutes'] ?? map['eta_minutes'] ?? map['eta']);
    if (status == current.status && eta == null) return;
    if (status.progressRank < current.status.progressRank) return;
    _setJob(current.copyWith(status: status, etaMinutes: eta));
  }

  /// Socket/API payloads send ETA as int, double, or numeric string.
  int? _etaMinutes(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    if (raw is String) {
      final parsed = num.tryParse(raw.trim());
      if (parsed == null) return null;
      return parsed.round();
    }
    return null;
  }

  void _setJob(ActiveJob? job) {
    final wasCompleted = state?.status == JobLifecycleStatus.completed;
    state = job;
    _syncRoom(job?.id);
    _syncAwaitingPaymentPoll(job);
    // A job just finished — make sure History reflects it without waiting
    // for the screen to be reopened.
    if (job?.status == JobLifecycleStatus.completed && !wasCompleted) {
      ref.invalidate(historyProvider);
    }
  }

  void _syncAwaitingPaymentPoll(ActiveJob? job) {
    final waiting = job?.status == JobLifecycleStatus.awaitingPayment;
    if (!waiting) {
      _awaitingPaymentPoll?.cancel();
      _awaitingPaymentPoll = null;
      return;
    }
    _awaitingPaymentPoll ??= Timer.periodic(
      _awaitingPaymentPollInterval,
      (_) => unawaited(_pollAwaitingPayment()),
    );
  }

  Future<void> _pollAwaitingPayment() async {
    final job = state;
    if (job == null || job.status != JobLifecycleStatus.awaitingPayment) {
      _awaitingPaymentPoll?.cancel();
      _awaitingPaymentPoll = null;
      return;
    }
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated ||
        auth.session.accessToken.startsWith('demo-')) {
      return;
    }
    try {
      final remote = await ref.read(jobsRepositoryProvider).getBooking(job.id);
      if (remote != null) _applyRemote(remote);
    } catch (_) {
      // Keep waiting; the next tick / socket event will reconcile.
    }
  }

  void _syncRoom(String? bookingId, {bool force = false}) {
    if (_joinedBookingId == bookingId) {
      if (force && bookingId != null && bookingId.isNotEmpty) {
        SocketService.instance.rejoinBooking(bookingId);
      }
      return;
    }
    if (_joinedBookingId != null) {
      SocketService.instance.leaveBooking(_joinedBookingId!);
    }
    _joinedBookingId = bookingId;
    if (bookingId != null && bookingId.isNotEmpty) {
      SocketService.instance.joinBooking(bookingId);
    }
  }

  void _leaveJoined() {
    if (_joinedBookingId == null) return;
    SocketService.instance.leaveBooking(_joinedBookingId!);
    _joinedBookingId = null;
  }

  /// Runs the single primary action for the current [JobLifecycleStatus].
  Future<void> performPrimaryAction() async {
    final job = state;
    final action = job?.primaryAction;
    if (job == null || action == null) return;

    // Optimistic status first so the UI advances immediately.
    final optimistic = job.copyWith(status: action.nextStatus);
    _setJob(optimistic);

    if (action.opensNativeMaps) {
      unawaited(openNativeNavigation(lat: job.lat, lng: job.lng));
    }

    try {
      final remote = await ref.read(jobsRepositoryProvider).updateStatus(
            job.id,
            action.nextStatus,
          );
      if (remote != null) _applyRemote(remote);
    } catch (_) {
      // Keep the optimistic status; the socket will reconcile if the API applied.
    }
  }

  Future<void> markCashReceived() async {
    final job = state;
    if (job == null) return;
    final remote =
        await ref.read(jobsRepositoryProvider).markCashReceived(job.id);
    if (remote != null) {
      _applyRemote(remote);
      return;
    }
    _setJob(job.copyWith(status: JobLifecycleStatus.completed));
  }

  Future<void> openMaps() async {
    final job = state;
    if (job == null) return;
    await openNativeNavigation(lat: job.lat, lng: job.lng);
  }
}

Map<String, dynamic>? _asMap(dynamic raw) {
  var value = raw;
  if (value is String) {
    try {
      value = jsonDecode(value);
    } catch (_) {
      return null;
    }
  }
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

ActiveJob mockJobFromFeed({
  required String id,
  required String jobType,
  required int farePaise,
  double lat = 12.9716,
  double lng = 77.5946,
}) {
  return ActiveJob(
    id: id,
    customerName: 'Asha Rao',
    customerPhone: '+919876543210',
    jobType: jobType,
    farePaise: farePaise,
    lat: lat,
    lng: lng,
    status: JobLifecycleStatus.assigned,
    notes: 'Ring the second-floor doorbell.',
  );
}
