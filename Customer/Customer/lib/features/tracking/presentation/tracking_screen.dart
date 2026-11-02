import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api_error.dart';
import '../../../core/socket_service.dart';
import '../../../core/theme.dart';
import '../../../core/visual_style.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/osm_tile_layer.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/data/rating_prompt_store.dart';
import '../../booking/domain/models.dart';
import '../../booking/presentation/rating_dialog.dart';
import '../../booking/providers/booking_providers.dart';
import '../../booking/providers/live_bookings_provider.dart';
import '../../history/data/mock_bookings.dart';
import '../data/booking_status_event.dart';
import '../data/tracking_ping.dart';
import 'booking_chat_sheet.dart';

class _LatLngTween extends Tween<LatLng> {
  _LatLngTween({required LatLng begin, required LatLng end})
      : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    final start = begin!;
    final finish = end!;
    return LatLng(
      start.latitude + (finish.latitude - start.latitude) * t,
      start.longitude + (finish.longitude - start.longitude) * t,
    );
  }
}

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with SingleTickerProviderStateMixin {
  static const _osmUserAgent = 'KRIYANTA-Customer/1.0 (coop-gig customer tracking)';
  static const _fallbackCenter = LatLng(12.9716, 77.5946);
  static const _defaultPingInterval = Duration(seconds: 8);

  final MapController _mapController = MapController();
  late final AnimationController _moveController;
  Animation<LatLng>? _moveAnimation;
  StreamSubscription<dynamic>? _statusSub;
  StreamSubscription<dynamic>? _trackingSub;

  late Booking _booking;
  int? _etaMinutes;
  bool _busy = false;
  bool _calling = false;
  bool _ratingPromptOpen = false;
  bool _mapReady = false;
  bool _didInitialFit = false;
  bool _openedSettle = false;
  LatLng? _workerDisplayed;
  LatLng? _workerTarget;
  DateTime? _lastPingAt;
  Duration _pingInterval = _defaultPingInterval;

  @override
  void initState() {
    super.initState();
    _booking = trackingSeed(widget.bookingId);
    _moveController = AnimationController(vsync: this)
      ..addListener(() {
        final value = _moveAnimation?.value;
        if (value == null) return;
        setState(() => _workerDisplayed = value);
      });
    _listenForUpdates();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(liveBookingsProvider.notifier).upsert(_booking);
      _loadInitial();
    });
  }

  String? get _currentUserId {
    final auth = ref.read(authProvider);
    if (auth is AuthAuthenticated) return auth.session.user?.id;
    return null;
  }

  LatLng get _destination {
    final address = _booking.address;
    if (address.lat == 0 && address.lng == 0) return _fallbackCenter;
    return LatLng(address.lat, address.lng);
  }

  bool get _hasWorkerLocation => _workerDisplayed != null;

  void _listenForUpdates() {
    final sockets = SocketService.instance;
    sockets.joinBooking(widget.bookingId);
    _statusSub = sockets.on('booking:status_update').listen(_onStatusUpdate);
    _trackingSub = sockets.on('tracking:update').listen(_onTrackingUpdate);
  }

  Future<void> _loadInitial() async {
    if (!looksLikeUuid(widget.bookingId) || isDemoSession(ref.read(authProvider))) {
      return;
    }
    final repo = ref.read(bookingsRepositoryProvider);
    try {
      final booking = await repo.get(
        widget.bookingId,
        currentUserId: _currentUserId,
      );
      if (!mounted) return;
      setState(() => _booking = booking);
      ref.read(liveBookingsProvider.notifier).upsert(booking);
      _maybeOpenSettle();
      _maybeOfferRatingOnLoad();
    } catch (_) {}

    try {
      final ping = await repo.getTracking(widget.bookingId);
      if (!mounted || ping == null) return;
      _applyPing(ping, animate: false);
    } catch (_) {}
  }

  void _onStatusUpdate(dynamic raw) {
    final update = BookingStatusUpdate.tryParse(raw);
    if (update == null || update.bookingId != widget.bookingId) return;

    final previousStatus = _booking.status;
    setState(() {
      _booking = _booking.copyWith(
        status: update.status,
        worker: update.worker,
        clearWorker: update.clearWorker,
      );
      if (update.etaMinutes != null) {
        _etaMinutes = update.etaMinutes;
      }
    });
    ref.read(liveBookingsProvider.notifier).applyStatusUpdate(update);

    final justCompleted = previousStatus != BookingStatus.completed &&
        update.status == BookingStatus.completed;
    if (justCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _offerLiveRating();
      });
    }
    _maybeOpenSettle();
  }

  void _maybeOpenSettle() {
    if (!mounted || _openedSettle) return;
    if (_booking.status != BookingStatus.awaitingPayment) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _openedSettle) return;
      if (_booking.status != BookingStatus.awaitingPayment) return;
      _openSettle();
    });
  }

  void _maybeOfferRatingOnLoad() {
    if (_booking.status != BookingStatus.completed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _offerLiveRating();
    });
  }

  Future<void> _offerLiveRating() async {
    if (!mounted || _ratingPromptOpen) return;
    if (_booking.status != BookingStatus.completed) return;
    if (_booking.customerRated) return;

    final store = ref.read(ratingPromptStoreProvider);
    if (await store.wasPrompted(widget.bookingId)) return;
    if (!mounted) return;

    _ratingPromptOpen = true;
    await store.markPrompted(widget.bookingId);
    if (!mounted) {
      _ratingPromptOpen = false;
      return;
    }
    try {
      await showBookingRatingDialog(context, booking: _booking);
    } finally {
      _ratingPromptOpen = false;
    }
  }

  void _onTrackingUpdate(dynamic raw) {
    final ping = TrackingPing.tryParse(raw);
    if (ping == null) return;
    if (ping.bookingId != null && ping.bookingId != widget.bookingId) return;
    _applyPing(ping, animate: true);
  }

  void _applyPing(TrackingPing ping, {required bool animate}) {
    final status = parseBookingStatus(ping.status);
    if (status != null && status != _booking.status) {
      setState(() => _booking = _booking.copyWith(status: status));
      ref.read(liveBookingsProvider.notifier).applyStatusUpdate(
            BookingStatusUpdate(bookingId: widget.bookingId, status: status),
          );
      _maybeOpenSettle();
    }

    final lat = ping.lat;
    final lng = ping.lng;
    if (lat == null || lng == null) return;

    final target = LatLng(lat, lng);
    final eta = ping.etaMinutes ??
        etaMinutesBetween(
          fromLat: lat,
          fromLng: lng,
          toLat: _destination.latitude,
          toLng: _destination.longitude,
        );
    final now = DateTime.now();
    if (_lastPingAt != null) {
      final delta = now.difference(_lastPingAt!);
      if (delta.inMilliseconds >= 2500 && delta.inMilliseconds <= 20000) {
        _pingInterval = delta;
      }
    }
    _lastPingAt = ping.updatedAt ?? now;
    _workerTarget = target;

    if (!animate || _workerDisplayed == null) {
      _moveController.stop();
      setState(() {
        _workerDisplayed = target;
        _etaMinutes = eta;
      });
      _fitCamera(initial: true);
      return;
    }

    setState(() => _etaMinutes = eta);
    _animateWorkerTo(target);
  }

  void _animateWorkerTo(LatLng target) {
    final from = _workerDisplayed ?? target;
    if (_samePoint(from, target)) {
      setState(() => _workerDisplayed = target);
      return;
    }
    _moveAnimation = _LatLngTween(begin: from, end: target).animate(
      CurvedAnimation(parent: _moveController, curve: Curves.linear),
    );
    _moveController
      ..duration = _pingInterval
      ..forward(from: 0);
  }

  bool _samePoint(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 0.00001 &&
        (a.longitude - b.longitude).abs() < 0.00001;
  }

  Future<void> _fitCamera({bool initial = false}) async {
    if (initial && _didInitialFit) return;
    if (!_mapReady) return;

    final dest = _destination;
    final worker = _workerDisplayed ?? _workerTarget;
    try {
      if (worker == null) {
        _mapController.move(dest, 15);
      } else {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints([dest, worker]),
            padding: const EdgeInsets.all(72),
            maxZoom: 16,
          ),
        );
      }
      if (initial && worker != null) _didInitialFit = true;
    } catch (_) {
      _mapController.move(dest, 14);
    }
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _trackingSub?.cancel();
    SocketService.instance.leaveBooking(widget.bookingId);
    _moveController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _recenter() => _fitCamera();

  void _openSettle() {
    if (_openedSettle) return;
    _openedSettle = true;
    context.go('/booking/${widget.bookingId}/settle', extra: _booking);
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('tracking.cancelTitle'.tr()),
        content: Text('tracking.cancelBody'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('tracking.cancelKeep'.tr()),
          ),
          PressScale(
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('tracking.cancelConfirm'.tr()),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      if (looksLikeUuid(widget.bookingId) &&
          !isDemoSession(ref.read(authProvider))) {
        final updated = await ref.read(bookingsRepositoryProvider).cancel(
              widget.bookingId,
              reason: 'Cancelled by customer',
            );
        ref.invalidate(myBookingsProvider);
        ref.read(liveBookingsProvider.notifier).upsert(updated);
        if (!mounted) return;
        setState(() => _booking = updated);
      } else {
        setState(() => _booking = _booking.copyWith(status: BookingStatus.cancelled));
        ref.read(liveBookingsProvider.notifier).upsert(
              _booking.copyWith(status: BookingStatus.cancelled),
            );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('tracking.cancelled'.tr())),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _call() async {
    if (_calling) return;
    setState(() => _calling = true);
    try {
      if (!looksLikeUuid(widget.bookingId) ||
          isDemoSession(ref.read(authProvider))) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('tracking.callUnavailable'.tr())),
        );
        return;
      }
      final result =
          await ref.read(bookingsRepositoryProvider).initiateCall(widget.bookingId);
      if (!mounted) return;
      if (!result.masked) {
        final number = _telNumber(result.phoneNumber);
        if (number == null) {
          throw StateError('tracking.callUnavailable'.tr());
        }
        final opened = await launchUrl(
          Uri(scheme: 'tel', path: number),
          mode: LaunchMode.externalApplication,
        );
        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('tracking.callDialFailed'.tr())),
          );
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('tracking.callPlaced'.tr())),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _calling = false);
    }
  }

  String? _telNumber(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  void _chat() {
    showBookingChatOverlay(
      context: context,
      bookingId: widget.bookingId,
      currentUserId: _currentUserId,
      initialMessages: _booking.messages,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final worker = _booking.worker;
    final dest = _destination;
    final waitingForPing = !_hasWorkerLocation;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: dest,
              initialZoom: 14,
              onMapReady: () {
                _mapReady = true;
                _fitCamera(initial: true);
              },
            ),
            children: [
              osmTileLayer(userAgent: _osmUserAgent),
              MarkerLayer(
                markers: [
                  Marker(
                    point: dest,
                    width: 44,
                    height: 44,
                    alignment: Alignment.bottomCenter,
                    child: Tooltip(
                      message: _booking.address.label,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  ),
                  if (_workerDisplayed != null)
                    Marker(
                      point: _workerDisplayed!,
                      width: 44,
                      height: 44,
                      alignment: Alignment.bottomCenter,
                      child: Tooltip(
                        message: worker?.name ?? 'Worker',
                        child: const Icon(
                          Icons.navigation,
                          color: Color(0xFF2B6CB0),
                          size: 36,
                        ),
                      ),
                    ),
                ],
              ),
              osmAttribution(),
            ],
          ),
          if (waitingForPing)
            const Positioned.fill(
              child: IgnorePointer(child: _WaitingMapState()),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Material(
                    color: theme.colorScheme.surface,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    elevation: 2,
                    child: IconButton(
                      tooltip: 'tracking.recenter'.tr(),
                      icon: const Icon(Icons.my_location),
                      onPressed: _recenter,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _TrackingSheet(
              booking: _booking,
              etaMinutes: _etaMinutes,
              waitingForTracking: waitingForPing &&
                  _booking.status != BookingStatus.requested,
              busy: _busy,
              calling: _calling,
              onCall: _call,
              onChat: _chat,
              onCancel: _booking.canCancel ? _cancel : null,
              onPay: _booking.status == BookingStatus.awaitingPayment
                  ? _openSettle
                  : null,
            ),
          ),
          if (_busy)
            const ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _WaitingMapState extends StatelessWidget {
  const _WaitingMapState();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 220),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_walk_outlined,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'tracking.waitingForWorker'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingSheet extends StatelessWidget {
  const _TrackingSheet({
    required this.booking,
    required this.onChat,
    this.etaMinutes,
    this.waitingForTracking = false,
    this.busy = false,
    this.calling = false,
    required this.onCall,
    this.onCancel,
    this.onPay,
  });

  final Booking booking;
  final int? etaMinutes;
  final bool waitingForTracking;
  final bool busy;
  final bool calling;
  final VoidCallback onCall;
  final VoidCallback onChat;
  final VoidCallback? onCancel;
  final VoidCallback? onPay;

  Color _badgeColor(ColorScheme scheme, BookingStatus status) {
    return switch (status) {
      BookingStatus.enRoute => scheme.tertiary,
      BookingStatus.inProgress => scheme.primary,
      BookingStatus.awaitingPayment => scheme.primary,
      BookingStatus.assigned => scheme.secondary,
      BookingStatus.completed => scheme.primary,
      BookingStatus.cancelled => scheme.error,
      BookingStatus.requested => scheme.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = _badgeColor(theme.colorScheme, booking.status);
    final label = trackingStatusLabel(booking.status);
    final worker = booking.worker;
    final finding = booking.status == BookingStatus.requested;
    final etaText = etaMinutes == null
        ? null
        : 'tracking.eta'.tr(args: ['$etaMinutes min']);
    final subtitle = finding
        ? 'tracking.searchingWorker'.tr()
        : waitingForTracking
            ? 'tracking.waitingForWorker'.tr()
            : (etaText ?? 'tracking.liveUpdates'.tr());

    return Material(
      elevation: 12,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Container(
                    key: ValueKey(label),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badge.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (statusEmoji(booking.status).isNotEmpty) ...[
                          Text(
                            statusEmoji(booking.status),
                            style: const TextStyle(fontSize: 12, height: 1),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          label,
                          style: theme.textTheme.labelLarge
                              ?.copyWith(color: badge),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: finding || worker == null
                  ? const CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      foregroundColor: AppColors.primary,
                      child: Icon(Icons.person_search_outlined),
                    )
                  : NameAvatar(
                      name: worker.name,
                      initials: worker.initials,
                      size: 40,
                    ),
              title: Text(
                worker?.name ?? 'tracking.searchingWorker'.tr(),
              ),
              subtitle: worker == null
                  ? Text('tracking.workerPending'.tr())
                  : Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text(worker.rating.toStringAsFixed(1)),
                      ],
                    ),
            ),
            if (onPay != null) ...[
              const SizedBox(height: 8),
              Text(
                'tracking.payOrCash'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              PressScale(
                enabled: !busy,
                child: FilledButton.icon(
                  onPressed: busy ? null : onPay,
                  icon: const Icon(Icons.payments_outlined),
                  label: Text('tracking.pay'.tr()),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: PressScale(
                    enabled: !busy && !calling,
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: (busy || calling) ? null : onCall,
                      icon: calling
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.call),
                      label: Text('common.call'.tr()),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PressScale(
                    enabled: !busy,
                    child: FilledButton.tonalIcon(
                      onPressed: busy ? null : onChat,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text('common.chat'.tr()),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onCancel,
                    icon: const Icon(Icons.close),
                    label: Text('common.cancel'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
