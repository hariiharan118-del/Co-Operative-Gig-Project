import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/api_error.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/osm_tile_layer.dart';
import '../data/nominatim_geocoder.dart';

class PickedMapAddress {
  const PickedMapAddress({
    required this.lat,
    required this.lng,
    required this.displayName,
    this.city,
    this.state,
    this.pincode,
  });

  final double lat;
  final double lng;
  final String displayName;
  final String? city;
  final String? state;
  final String? pincode;
}

class PickLocationMapScreen extends StatefulWidget {
  const PickLocationMapScreen({
    super.key,
    required this.initial,
  });

  final LatLng initial;

  @override
  State<PickLocationMapScreen> createState() => _PickLocationMapScreenState();
}

class _PickLocationMapScreenState extends State<PickLocationMapScreen> {
  static const _userAgent = nominatimUserAgent;

  final MapController _mapController = MapController();
  final NominatimGeocoder _geocoder = NominatimGeocoder();
  bool _mapReady = false;
  bool _busy = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _center {
    if (!_mapReady) return widget.initial;
    return _mapController.camera.center;
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    final point = _center;
    try {
      final result = await _geocoder.reverse(lat: point.latitude, lng: point.longitude);
      if (!mounted) return;
      Navigator.of(context).pop(
        PickedMapAddress(
          lat: point.latitude,
          lng: point.longitude,
          displayName: result.displayName,
          city: result.city,
          state: result.state,
          pincode: result.pincode,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : 'profile.geocodeFailed'.tr();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('profile.pickOnMapTitle'.tr())),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.initial,
                    initialZoom: 16,
                    interactionOptions: InteractionOptions(
                      flags: _busy
                          ? InteractiveFlag.none
                          : InteractiveFlag.all,
                    ),
                    onMapReady: () => _mapReady = true,
                  ),
                  children: [
                    osmTileLayer(userAgent: _userAgent),
                    osmAttribution(),
                  ],
                ),
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 36),
                      child: Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 44,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'profile.pickOnMapHint'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PressScale(
                    enabled: !_busy,
                    child: FilledButton(
                      onPressed: _busy ? null : _confirm,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('profile.confirmLocation'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
