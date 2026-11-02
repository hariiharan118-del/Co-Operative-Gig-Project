import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_error.dart';
import '../../../core/socket_service.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../history/data/mock_bookings.dart';
import '../../tracking/data/booking_status_event.dart';
import '../domain/models.dart';
import '../providers/booking_providers.dart';
import '../providers/live_bookings_provider.dart';

class AwaitingPaymentScreen extends ConsumerStatefulWidget {
  const AwaitingPaymentScreen({
    super.key,
    required this.bookingId,
    this.booking,
  });

  final String bookingId;
  final Booking? booking;

  @override
  ConsumerState<AwaitingPaymentScreen> createState() =>
      _AwaitingPaymentScreenState();
}

class _AwaitingPaymentScreenState extends ConsumerState<AwaitingPaymentScreen> {
  static const _paymentPollInterval = Duration(seconds: 2);

  Booking? _booking;
  StreamSubscription<dynamic>? _statusSub;
  Timer? _paymentPoll;
  bool _loading = true;
  bool _choseDirect = false;
  bool _leaving = false;

  String? get _currentUserId {
    final auth = ref.read(authProvider);
    if (auth is AuthAuthenticated) return auth.session.user?.id;
    return null;
  }

  String get _workerName {
    final name = _booking?.worker?.name.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'tracking.workerFallback'.tr();
  }

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _listenForUpdates();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _paymentPoll?.cancel();
    SocketService.instance.leaveBooking(widget.bookingId);
    super.dispose();
  }

  void _listenForUpdates() {
    SocketService.instance.joinBooking(widget.bookingId);
    _statusSub =
        SocketService.instance.on('booking:status_update').listen(_onStatusUpdate);
  }

  void _onStatusUpdate(dynamic raw) {
    final update = BookingStatusUpdate.tryParse(raw);
    if (update == null || update.bookingId != widget.bookingId) return;

    final next = (_booking ?? widget.booking)?.copyWith(
      status: update.status,
      worker: update.worker,
      clearWorker: update.clearWorker,
    );
    if (next != null) {
      setState(() => _booking = next);
      ref.read(liveBookingsProvider.notifier).applyStatusUpdate(update);
    }
    _goTrackingIfPaid();
    _syncPaymentPoll();
  }

  Future<void> _load() async {
    final seeded = _booking;
    if (seeded != null) {
      setState(() => _loading = false);
      _goTrackingIfPaid();
      _syncPaymentPoll();
    }

    if (!looksLikeUuid(widget.bookingId) ||
        isDemoSession(ref.read(authProvider))) {
      setState(() {
        _booking ??= trackingSeed(widget.bookingId);
        _loading = false;
      });
      _goTrackingIfPaid();
      return;
    }

    try {
      final booking = await ref.read(bookingsRepositoryProvider).get(
            widget.bookingId,
            currentUserId: _currentUserId,
          );
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _loading = false;
      });
      ref.read(liveBookingsProvider.notifier).upsert(booking);
      _goTrackingIfPaid();
      _syncPaymentPoll();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _booking ??= trackingSeed(widget.bookingId);
        _loading = false;
      });
    }
  }

  /// Fallback for a missed/delayed `booking:status_update` socket event:
  /// poll the booking every 2s while payment is pending so "did payment
  /// go through yet" never waits on the socket alone.
  void _syncPaymentPoll() {
    final waiting = _booking?.status == BookingStatus.awaitingPayment;
    if (!waiting ||
        !looksLikeUuid(widget.bookingId) ||
        isDemoSession(ref.read(authProvider))) {
      _paymentPoll?.cancel();
      _paymentPoll = null;
      return;
    }
    _paymentPoll ??= Timer.periodic(
      _paymentPollInterval,
      (_) => unawaited(_pollPayment()),
    );
  }

  Future<void> _pollPayment() async {
    if (_booking?.status != BookingStatus.awaitingPayment) {
      _paymentPoll?.cancel();
      _paymentPoll = null;
      return;
    }
    try {
      final booking = await ref.read(bookingsRepositoryProvider).get(
            widget.bookingId,
            currentUserId: _currentUserId,
          );
      if (!mounted) return;
      setState(() => _booking = booking);
      ref.read(liveBookingsProvider.notifier).upsert(booking);
      _goTrackingIfPaid();
      _syncPaymentPoll();
    } catch (_) {
      // Keep waiting; the next tick / socket event will reconcile.
    }
  }

  void _goTrackingIfPaid() {
    if (!mounted || _leaving) return;
    if (_booking?.status != BookingStatus.completed) return;
    _leaving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go('/tracking/${widget.bookingId}');
    });
  }

  void _payNow() {
    final booking = _booking;
    context.push(
      '/booking/${widget.bookingId}/pay',
      extra: booking,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(liveBookingsProvider, (previous, next) {
      final live = next.byId(widget.bookingId);
      if (live == null) return;
      if (_booking?.status != live.status ||
          _booking?.worker?.id != live.worker?.id) {
        setState(() => _booking = live);
      }
      _goTrackingIfPaid();
      _syncPaymentPoll();
    });

    final booking = _booking;
    final amount = booking?.totalPaise ?? 0;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('booking.payChoiceTitle'.tr())),
      body: _loading && booking == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  booking?.categoryName ?? 'booking.category'.tr(),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  formatPaise(amount),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'booking.payChoiceHint'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _workerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_choseDirect) ...[
                  const SizedBox(height: 16),
                  AppCard(
                    color: AppColors.primarySoft,
                    borderColor: AppColors.primary.withValues(alpha: 0.22),
                    child: Text(
                      'booking.payDirectTitle'.tr(),
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PressScale(
                child: FilledButton.icon(
                  onPressed: _payNow,
                  icon: const Icon(Icons.payments_outlined),
                  label: Text('booking.payNow'.tr()),
                ),
              ),
              const SizedBox(height: 10),
              if (_choseDirect)
                Text(
                  'booking.payDirectBody'.tr(args: [_workerName]),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                )
              else ...[
                PressScale(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _choseDirect = true),
                    icon: const Icon(Icons.handshake_outlined),
                    label: Text(
                      'booking.payDirect'.tr(args: [_workerName]),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'booking.payDirectBody'.tr(args: [_workerName]),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
