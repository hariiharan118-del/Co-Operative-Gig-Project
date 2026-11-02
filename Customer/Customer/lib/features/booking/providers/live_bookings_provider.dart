import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/socket_service.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../history/data/mock_bookings.dart';
import '../../tracking/data/booking_status_event.dart';
import '../../tracking/data/tracking_ping.dart';
import '../domain/models.dart';
import 'booking_providers.dart';

class LiveBookingsState {
  const LiveBookingsState({
    this.bookings = const [],
    this.etas = const {},
  });

  final List<Booking> bookings;
  final Map<String, int> etas;

  Booking? get active => findActiveBooking(bookings);

  Booking? byId(String id) {
    for (final booking in bookings) {
      if (booking.id == id) return booking;
    }
    return null;
  }

  int? etaFor(String id) => etas[id];
}

class ActiveBookingSnapshot {
  const ActiveBookingSnapshot({
    required this.booking,
    this.etaMinutes,
  });

  final Booking booking;
  final int? etaMinutes;
}

final liveBookingsProvider =
    NotifierProvider<LiveBookingsNotifier, LiveBookingsState>(
  LiveBookingsNotifier.new,
);

final activeBookingProvider = Provider<ActiveBookingSnapshot?>((ref) {
  final live = ref.watch(liveBookingsProvider);
  final booking = live.active;
  if (booking == null) return null;
  return ActiveBookingSnapshot(
    booking: booking,
    etaMinutes: live.etaFor(booking.id),
  );
});

class LiveBookingsNotifier extends Notifier<LiveBookingsState> {
  final _overrides = <String, Booking>{};
  final _etas = <String, int>{};
  final _joined = <String>{};
  List<Booking> _rest = const [];
  String _sessionKey = '';
  StreamSubscription<dynamic>? _statusSub;
  StreamSubscription<dynamic>? _trackingSub;

  @override
  LiveBookingsState build() {
    ref.onDispose(_cleanup);

    final sessionKey = ref.watch(
      authProvider.select((auth) {
        if (auth is! AuthAuthenticated) return '';
        if (isDemoSession(auth)) return 'demo';
        return auth.session.user?.id ?? 'user';
      }),
    );
    final auth = ref.read(authProvider);
    if (sessionKey != _sessionKey) {
      _sessionKey = sessionKey;
      _overrides.clear();
      _etas.clear();
      _rest = const [];
      _leaveJoinedRooms();
      _cancelSocketListeners();
    }

    if (auth is! AuthAuthenticated) {
      _cancelSocketListeners();
      return const LiveBookingsState();
    }

    if (isDemoSession(auth)) {
      _cancelSocketListeners();
      return _compose(base: mockHistory);
    }

    _listenToSockets();
    ref.listen<AsyncValue<List<Booking>>>(myBookingsProvider, (previous, next) {
      final list = next.valueOrNull;
      if (list == null) return;
      _rest = list;
      _dropCaughtUpOverrides(list);
      state = _compose(base: _rest);
    });
    final initial = ref.read(myBookingsProvider).valueOrNull;
    if (initial != null) {
      _rest = initial;
      _dropCaughtUpOverrides(initial);
    }
    return _compose(base: _rest);
  }

  void upsert(Booking booking) {
    _overrides[booking.id] = booking;
    state = _compose(base: _baseList());
  }

  void markCustomerRated(String bookingId) {
    final current = state.byId(bookingId) ?? _overrides[bookingId];
    if (current == null) return;
    _overrides[bookingId] = current.copyWith(customerRated: true);
    state = _compose(base: _baseList());
  }

  void applyStatusUpdate(BookingStatusUpdate update) {
    final current = state.byId(update.bookingId) ?? _overrides[update.bookingId];
    if (current == null) {
      if (update.status?.isTrackable == true) {
        ref.invalidate(myBookingsProvider);
      }
      return;
    }

    _overrides[update.bookingId] = current.copyWith(
      status: update.status,
      worker: update.worker,
      clearWorker: update.clearWorker,
    );
    if (update.etaMinutes != null) {
      _etas[update.bookingId] = update.etaMinutes!;
    }
    state = _compose(base: _baseList());

    if (update.status == BookingStatus.completed ||
        update.status == BookingStatus.cancelled) {
      ref.invalidate(myBookingsProvider);
    }
  }

  List<Booking> _baseList() {
    final auth = ref.read(authProvider);
    if (isDemoSession(auth)) return mockHistory;
    return _rest;
  }

  LiveBookingsState _compose({required List<Booking> base}) {
    final merged = _merge(base, _overrides);
    _syncRooms(merged);
    return LiveBookingsState(
      bookings: merged,
      etas: Map<String, int>.from(_etas),
    );
  }

  List<Booking> _merge(List<Booking> rest, Map<String, Booking> overrides) {
    final byId = <String, Booking>{
      for (final booking in rest) booking.id: booking,
    };
    for (final overlay in overrides.values) {
      final existing = byId[overlay.id];
      if (existing == null) {
        byId[overlay.id] = overlay;
        continue;
      }
      byId[overlay.id] = existing.copyWith(
        status: overlay.status,
        worker: overlay.worker,
        customerRated: existing.customerRated || overlay.customerRated,
        clearWorker: overlay.worker == null && !overlay.status.isTrackable,
      );
    }
    final list = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void _dropCaughtUpOverrides(List<Booking> rest) {
    for (final booking in rest) {
      final overlay = _overrides[booking.id];
      if (overlay == null) continue;
      if (overlay.customerRated && !booking.customerRated) continue;
      if (!booking.status.isTrackable ||
          booking.status.progressRank >= overlay.status.progressRank) {
        _overrides.remove(booking.id);
      }
    }
  }

  void _listenToSockets() {
    if (_statusSub != null) return;
    final sockets = SocketService.instance;
    _statusSub = sockets.on('booking:status_update').listen((raw) {
      final update = BookingStatusUpdate.tryParse(raw);
      if (update == null) return;
      applyStatusUpdate(update);
    });
    _trackingSub = sockets.on('tracking:update').listen((raw) {
      final ping = TrackingPing.tryParse(raw);
      if (ping == null || ping.etaMinutes == null) return;
      final id = ping.bookingId ?? state.active?.id;
      if (id == null) return;
      _etas[id] = ping.etaMinutes!;
      state = _compose(base: _baseList());
    });
  }

  void _syncRooms(List<Booking> bookings) {
    final wanted = {
      for (final booking in bookings)
        if (booking.isTrackable) booking.id,
    };
    for (final id in wanted.difference(_joined)) {
      SocketService.instance.joinBooking(id);
      _joined.add(id);
    }
    for (final id in _joined.difference(wanted)) {
      SocketService.instance.leaveBooking(id);
    }
    _joined
      ..clear()
      ..addAll(wanted);
  }

  void _leaveJoinedRooms() {
    for (final id in _joined) {
      SocketService.instance.leaveBooking(id);
    }
    _joined.clear();
  }

  void _cancelSocketListeners() {
    _statusSub?.cancel();
    _trackingSub?.cancel();
    _statusSub = null;
    _trackingSub = null;
  }

  void _cleanup() {
    _cancelSocketListeners();
    _leaveJoinedRooms();
  }
}
