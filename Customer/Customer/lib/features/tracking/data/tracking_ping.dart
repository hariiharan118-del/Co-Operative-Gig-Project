import 'dart:math' as math;

import '../../booking/data/booking_mapper.dart';

class TrackingPing {
  const TrackingPing({
    this.lat,
    this.lng,
    this.bookingId,
    this.etaMinutes,
    this.updatedAt,
    this.status,
  });

  final double? lat;
  final double? lng;
  final String? bookingId;
  final int? etaMinutes;
  final DateTime? updatedAt;
  final String? status;

  static TrackingPing? tryParse(dynamic raw) {
    final map = asJsonMap(raw);
    if (map == null) return null;

    final nested = asJsonMap(map['worker']) ?? asJsonMap(map['location']);
    final lat = _coord(map['lat'] ?? map['latitude'] ?? nested?['lat']);
    final lng = _coord(map['lng'] ?? map['lon'] ?? map['longitude'] ?? nested?['lng']);
    final status = asString(map['status'] ?? map['bookingStatus']);
    if (lat == null && lng == null && status == null) return null;

    return TrackingPing(
      lat: lat,
      lng: lng,
      bookingId: asString(map['bookingId'] ?? map['booking_id']),
      etaMinutes: _int(map['etaMinutes'] ?? map['eta_minutes'] ?? map['eta']),
      updatedAt: asDate(map['updatedAt'] ?? map['updated_at'] ?? map['at']),
      status: status,
    );
  }

  static double? _coord(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

int etaMinutesBetween({
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
}) {
  const earthRadiusKm = 6371.0;
  const averageSpeedKmh = 25.0;
  double toRad(double deg) => deg * math.pi / 180;
  final dLat = toRad(toLat - fromLat);
  final dLng = toRad(toLng - fromLng);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(toRad(fromLat)) *
          math.cos(toRad(toLat)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final km = 2 * earthRadiusKm * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
  if (km < 0.05) return 0;
  final minutes = ((km / averageSpeedKmh) * 60).round();
  return minutes < 1 ? 1 : minutes;
}
