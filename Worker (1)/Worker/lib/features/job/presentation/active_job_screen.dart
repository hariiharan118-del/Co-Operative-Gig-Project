import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/api_error.dart';
import '../../../core/maps_launcher.dart';
import '../../../core/money.dart';
import '../../../core/socket_service.dart';
import '../../../core/theme.dart';
import '../../../core/visual_style.dart';
import '../../../core/widgets/osm_tile_layer.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/sky_widgets.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../domain/active_job.dart';
import '../providers/active_job_provider.dart';
import 'booking_chat_sheet.dart';

class ActiveJobScreen extends ConsumerStatefulWidget {
  const ActiveJobScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen>
    with WidgetsBindingObserver {
  static const _pingInterval = Duration(seconds: 5);
  static const _osmUserAgent =
      'KRIYANTAPartner/1.0 (com.coopgig.coop_gig_worker)';

  final MapController _mapController = MapController();
  Timer? _pingTimer;
  LatLng? _workerPos;
  bool _fittedOnce = false;
  bool _mapReady = false;
  String? _pingingBookingId;

  bool _ready = false;
  bool _calling = false;
  bool _paying = false;
  bool _acting = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(activeJobProvider.notifier).ensure(widget.jobId);
      if (!mounted) return;
      SocketService.instance.joinBooking(widget.jobId);
      SocketService.instance.joinChat(widget.jobId);
      setState(() => _ready = true);
      _syncLocationPinger(ref.read(activeJobProvider));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_onResumed());
  }

  Future<void> _onResumed() async {
    if (!mounted) return;
    SocketService.instance.rejoinBooking(widget.jobId);
    await ref
        .read(activeJobProvider.notifier)
        .ensure(widget.jobId, forceRefresh: true);
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await ref
          .read(activeJobProvider.notifier)
          .ensure(widget.jobId, forceRefresh: true);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _markCashReceived() async {
    if (_paying) return;
    setState(() => _paying = true);
    try {
      await ref.read(activeJobProvider.notifier).markCashReceived();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('job.paid'.tr())),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeApiError(error))),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _onPrimary(ActiveJob job) async {
    final action = job.primaryAction;
    if (action == null) {
      ref.read(activeJobProvider.notifier).clear();
      context.go('/dashboard');
      return;
    }
    if (_acting) return;
    setState(() => _acting = true);
    try {
      await ref.read(activeJobProvider.notifier).performPrimaryAction();
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _callCustomer(String bookingId) async {
    if (_calling) return;
    setState(() => _calling = true);
    try {
      final result =
          await ref.read(jobsRepositoryProvider).initiateCall(bookingId);
      if (!mounted) return;
      if (!result.masked &&
          result.phoneNumber != null &&
          result.phoneNumber!.isNotEmpty) {
        final opened = await openPhoneDialer(result.phoneNumber!);
        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('job.callDialFailed'.tr())),
          );
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('job.callPlaced'.tr())),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeApiError(error))),
      );
    } finally {
      if (mounted) setState(() => _calling = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLocationPinger();
    SocketService.instance.leaveChat(widget.jobId);
    SocketService.instance.leaveBooking(widget.jobId);
    _mapController.dispose();
    super.dispose();
  }

  void _syncLocationPinger(ActiveJob? job) {
    if (job == null || !job.status.shouldPingLocation) {
      _stopLocationPinger();
      return;
    }
    if (_pingingBookingId == job.id && _pingTimer != null) return;
    _startLocationPinger(job.id);
  }

  void _startLocationPinger(String bookingId) {
    _stopLocationPinger();
    _pingingBookingId = bookingId;
    unawaited(_pingOnce(bookingId));
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      unawaited(_pingOnce(bookingId));
    });
  }

  void _stopLocationPinger() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _pingingBookingId = null;
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _pingOnce(String bookingId) async {
    try {
      if (!await _ensureLocationPermission()) return;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted || _pingingBookingId != bookingId) return;

      final here = LatLng(position.latitude, position.longitude);
      SocketService.instance.emit('location:ping', {
        'bookingId': bookingId,
        'lat': position.latitude,
        'lng': position.longitude,
      });

      setState(() => _workerPos = here);
      if (!_fittedOnce) {
        final job = ref.read(activeJobProvider);
        if (job != null) {
          _fitBoth(LatLng(job.lat, job.lng), here);
        }
      }
    } catch (_) {
      // Permission denied, timeout, or web geolocation blocked.
    }
  }

  Future<void> _fitBoth(LatLng a, LatLng b) async {
    if (!_mapReady) return;
    _fittedOnce = true;

    final sameSpot = (a.latitude - b.latitude).abs() < 0.00005 &&
        (a.longitude - b.longitude).abs() < 0.00005;
    if (sameSpot) {
      _mapController.move(a, 15);
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([a, b]),
        padding: const EdgeInsets.all(72),
        maxZoom: 16,
      ),
    );
  }

  Future<void> _recenter(ActiveJob job) async {
    final dest = LatLng(job.lat, job.lng);
    final worker = _workerPos;
    if (worker != null) {
      await _fitBoth(dest, worker);
      return;
    }
    if (_mapReady) _mapController.move(dest, 15);
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(activeJobProvider);
    ref.listen<ActiveJob?>(activeJobProvider, (_, next) {
      _syncLocationPinger(next);
    });

    if (job == null || job.id != widget.jobId) {
      return SkyScaffold(
        title: 'job.notFound'.tr(),
        showBack: true,
        body: Center(
          child: _ready
              ? Text('job.notFound'.tr())
              : const CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final dest = LatLng(job.lat, job.lng);
    final worker = _workerPos;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: dest,
              initialZoom: 14.5,
              onMapReady: () {
                _mapReady = true;
                final here = _workerPos;
                if (here != null && !_fittedOnce) {
                  unawaited(_fitBoth(dest, here));
                }
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
                      message: '${job.customerName}\n${job.jobType}',
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.teal,
                        size: 40,
                      ),
                    ),
                  ),
                  if (worker != null)
                    Marker(
                      point: worker,
                      width: 44,
                      height: 44,
                      alignment: Alignment.bottomCenter,
                      child: const Tooltip(
                        message: 'You',
                        child: Icon(
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.chevron_left_rounded,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/dashboard');
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  _EtaPill(
                    distanceKm: job.distanceKm,
                    etaMinutes: job.etaMinutes,
                  ),
                  const Spacer(),
                  CircleIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: _refreshing ? null : _refresh,
                  ),
                  const SizedBox(width: 10),
                  CircleIconButton(
                    icon: Icons.my_location_rounded,
                    onPressed: () => _recenter(job),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _JobSheet(
              job: job,
              calling: _calling,
              paying: _paying,
              acting: _acting,
              onCall: () => _callCustomer(job.id),
              onPay: _markCashReceived,
              onPrimary: () => _onPrimary(job),
            ),
          ),
        ],
      ),
    );
  }
}

class _EtaPill extends StatelessWidget {
  const _EtaPill({required this.distanceKm, required this.etaMinutes});

  final double distanceKm;
  final int etaMinutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me_rounded, size: 18, color: AppColors.teal),
          const SizedBox(width: 8),
          Text(
            'job.etaPill'.tr(args: [
              '${distanceKm.toStringAsFixed(1)} km',
              '$etaMinutes min',
            ]),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _JobSheet extends ConsumerWidget {
  const _JobSheet({
    required this.job,
    required this.calling,
    required this.paying,
    required this.acting,
    required this.onCall,
    required this.onPay,
    required this.onPrimary,
  });

  final ActiveJob job;
  final bool calling;
  final bool paying;
  final bool acting;
  final VoidCallback onCall;
  final VoidCallback onPay;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = job.primaryAction;

    return Material(
      color: AppColors.card,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                NameAvatar(
                  name: job.customerName,
                  size: 48,
                  borderRadius: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.customerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        job.jobType,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatPaise(job.farePaise),
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(width: 8),
                CircleIconButton(
                  icon: Icons.navigation_rounded,
                  background: AppColors.teal,
                  foreground: Colors.white,
                  onPressed: () =>
                      ref.read(activeJobProvider.notifier).openMaps(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SkyChip(label: job.status.labelKey.tr()),
            const SizedBox(height: 16),
            if (job.status == JobLifecycleStatus.awaitingPayment) ...[
              Text(
                'job.paymentReceivedHint'.tr(),
                style: const TextStyle(color: AppColors.muted, height: 1.35),
              ),
              const SizedBox(height: 12),
              PressScale(
                enabled: !paying,
                child: FilledButton(
                  onPressed: paying ? null : onPay,
                  child: paying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('job.paymentReceived'.tr()),
                ),
              ),
            ] else ...[
              PressScale(
                enabled: !acting,
                child: FilledButton(
                  onPressed: acting ? null : onPrimary,
                  child: acting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          action == null
                              ? 'job.actionDone'.tr()
                              : action.labelKey.tr(),
                        ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: calling ? null : onCall,
                    icon: const Icon(Icons.call_outlined),
                    label: Text('common.call'.tr()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () => showBookingChatOverlay(
                      context: context,
                      bookingId: job.id,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text('common.chat'.tr()),
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
