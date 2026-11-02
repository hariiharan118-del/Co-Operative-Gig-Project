import '../../job/domain/active_job.dart';

class NearbyJob {
  const NearbyJob({
    required this.id,
    required this.serviceType,
    required this.distanceKm,
    required this.estimatedPayPaise,
    this.addressLine = '',
    this.areaCode = 'BLR',
    this.areaName = 'Bengaluru',
    this.lat = 12.9716,
    this.lng = 77.5946,
    this.customerName = '',
    this.customerPhone = '',
    this.notes,
    this.isEmergency = false,
  });

  final String id;
  final String serviceType;
  final double distanceKm;
  final int estimatedPayPaise;
  final String addressLine;
  final String areaCode;
  final String areaName;
  final double lat;
  final double lng;
  final String customerName;
  final String customerPhone;
  final String? notes;
  final bool isEmergency;

  static NearbyJob? tryParse(dynamic raw) {
    final map = _asMap(raw);
    if (map == null) return null;
    final nested = _asMap(map['booking']) ??
        ((map['id'] == null && map['bookingId'] == null) ? _asMap(map['data']) : null);
    try {
      return NearbyJob.fromJson(nested ?? map);
    } catch (_) {
      return null;
    }
  }

  factory NearbyJob.fromJson(Map<String, dynamic> json) {
    final booking = _asMap(json['booking']) ?? json;
    final id = (booking['id'] ?? booking['bookingId'] ?? '').toString();
    if (id.isEmpty) {
      throw const FormatException('Booking is missing id');
    }

    final category = _asMap(booking['serviceCategory']) ??
        _asMap(booking['service']) ??
        _asMap(booking['category']);
    final serviceType = (category?['name'] ??
            category?['slug'] ??
            booking['serviceType'] ??
            booking['jobType'] ??
            'Job')
        .toString();

    final address = _asMap(booking['address']);
    final addressLine = _addressLine(address, booking);
    final areaName = (address?['city'] ??
            address?['label'] ??
            booking['areaName'] ??
            booking['area'] ??
            'Bengaluru')
        .toString();
    final areaCode = (booking['areaCode'] ?? _areaCode(areaName)).toString();

    final payment = _asMap(booking['payment']);
    final pay = payment?['amount'] ??
        booking['estimatedPayPaise'] ??
        booking['farePaise'] ??
        booking['amount'] ??
        category?['basePricing'] ??
        0;

    final customer = _asMap(booking['customer']);
    final profile = _asMap(customer?['customerProfile']);
    final customerName = (profile?['name'] ??
            customer?['name'] ??
            booking['customerName'] ??
            '')
        .toString();
    final customerPhone = (customer?['phone'] ?? booking['customerPhone'] ?? '')
        .toString();

    return NearbyJob(
      id: id,
      serviceType: serviceType,
      distanceKm: _distanceKm(booking),
      estimatedPayPaise: _toPaise(pay),
      addressLine: addressLine,
      areaCode: areaCode,
      areaName: areaName,
      lat: _toDouble(address?['lat'] ?? booking['lat']) ?? 12.9716,
      lng: _toDouble(address?['lng'] ?? booking['lng']) ?? 77.5946,
      customerName: customerName,
      customerPhone: customerPhone,
      notes: booking['notes']?.toString(),
      isEmergency: booking['isEmergency'] == true,
    );
  }

  ActiveJob toActiveJob({JobLifecycleStatus? status}) {
    return ActiveJob(
      id: id,
      customerName: customerName.isEmpty ? 'Customer' : customerName,
      customerPhone: customerPhone,
      jobType: serviceType,
      farePaise: estimatedPayPaise,
      lat: lat,
      lng: lng,
      status: status ?? JobLifecycleStatus.assigned,
      distanceKm: distanceKm,
      notes: notes,
    );
  }
}

ActiveJob? activeJobFromBooking(dynamic raw) {
  final nearby = NearbyJob.tryParse(raw);
  if (nearby == null) return null;
  final map = _asMap(raw);
  final booking = _asMap(map?['booking']) ?? map;
  final status =
      jobLifecycleFromApi(booking?['status']) ?? JobLifecycleStatus.assigned;
  return nearby.toActiveJob(status: status);
}

/// Thrown when POST accept returns HTTP 409 — another worker took the job.
class JobTakenException implements Exception {
  const JobTakenException();
}

String? bookingIdFromPayload(dynamic data) {
  if (data is String && data.isNotEmpty) return data;
  final map = _asMap(data);
  if (map == null) return null;
  final nested = _asMap(map['booking']);
  final id = map['id'] ??
      map['bookingId'] ??
      nested?['id'] ??
      nested?['bookingId'];
  if (id == null) return null;
  final value = id.toString();
  return value.isEmpty ? null : value;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _addressLine(Map<String, dynamic>? address, Map<String, dynamic> booking) {
  if (address != null) {
    final parts = [
      address['line1'],
      address['line2'],
      address['city'],
    ]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .map((e) => e.toString().trim());
    final joined = parts.join(', ');
    if (joined.isNotEmpty) return joined;
  }
  final fallback = booking['addressLine'] ?? booking['address'];
  if (fallback is String && fallback.trim().isNotEmpty) return fallback.trim();
  return '';
}

String _areaCode(String areaName) {
  final letters = areaName.replaceAll(RegExp('[^A-Za-z]'), '');
  if (letters.length >= 3) return letters.substring(0, 3).toUpperCase();
  if (letters.isNotEmpty) return letters.toUpperCase().padRight(3, 'X');
  return 'JOB';
}

double _distanceKm(Map<String, dynamic> booking) {
  final km = _toDouble(
    booking['distanceKm'] ?? booking['distance_km'] ?? booking['distance'],
  );
  if (km != null) {
    // Distances >= 50 without a km key are treated as metres.
    if (booking['distanceKm'] == null &&
        booking['distance_km'] == null &&
        km >= 50) {
      return km / 1000;
    }
    return km;
  }
  final metres = _toDouble(booking['distanceMeters'] ?? booking['distance_m']);
  if (metres != null) return metres / 1000;
  return 0;
}

int _toPaise(dynamic value) {
  if (value == null) return 0;
  if (value is int) {
    return value >= 1000 ? value : value * 100;
  }
  if (value is double) {
    return (value * 100).round();
  }
  if (value is String) {
    final parsed = num.tryParse(value.trim());
    if (parsed == null) return 0;
    if (value.contains('.')) return (parsed * 100).round();
    return parsed >= 1000 ? parsed.round() : (parsed * 100).round();
  }
  return 0;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}
