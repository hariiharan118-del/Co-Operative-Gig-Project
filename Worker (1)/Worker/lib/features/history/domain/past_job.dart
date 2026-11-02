class PastJob {
  const PastJob({
    required this.id,
    required this.serviceType,
    required this.customerName,
    required this.earnedPaise,
    required this.completedAt,
    this.addressLine = '',
    this.areaCode = 'BLR',
    this.areaName = 'Bengaluru',
  });

  final String id;
  final String serviceType;
  final String customerName;
  final int earnedPaise;
  final DateTime completedAt;
  final String addressLine;
  final String areaCode;
  final String areaName;

  /// Parses a completed `Booking` row from `GET /bookings?status=COMPLETED`.
  static PastJob? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final booking = Map<String, dynamic>.from(raw);
    final id = '${booking['id'] ?? ''}';
    if (id.isEmpty) return null;

    final category = _asMap(booking['serviceCategory']);
    final serviceType = (category?['name'] ?? 'Job').toString();

    final customer = _asMap(booking['customer']);
    final profile = _asMap(customer?['customerProfile']);
    final customerName =
        (profile?['name'] ?? customer?['phone'] ?? '').toString();

    final address = _asMap(booking['address']);
    final addressLine = _addressLine(address);
    final areaName = (address?['city'] ?? 'Bengaluru').toString();
    final areaCode = _areaCode(areaName);

    final payment = _asMap(booking['payment']);
    final earnedPaise = _toPaise(payment?['amount']);

    final completedAt =
        DateTime.tryParse('${booking['updatedAt'] ?? ''}') ?? DateTime.now();

    return PastJob(
      id: id,
      serviceType: serviceType,
      customerName: customerName.isEmpty ? 'Customer' : customerName,
      earnedPaise: earnedPaise,
      completedAt: completedAt,
      addressLine: addressLine,
      areaCode: areaCode,
      areaName: areaName,
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _addressLine(Map<String, dynamic>? address) {
  if (address == null) return '';
  final parts = [address['line1'], address['line2'], address['city']]
      .where((e) => e != null && e.toString().trim().isNotEmpty)
      .map((e) => e.toString().trim());
  return parts.join(', ');
}

String _areaCode(String areaName) {
  final letters = areaName.replaceAll(RegExp('[^A-Za-z]'), '');
  if (letters.length >= 3) return letters.substring(0, 3).toUpperCase();
  if (letters.isNotEmpty) return letters.toUpperCase().padRight(3, 'X');
  return 'JOB';
}

/// Payment amounts serialize as a decimal string (e.g. "349.00") or a plain
/// integer already in paise; mirrors the same convention used for job pay
/// estimates in nearby_job.dart.
int _toPaise(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value >= 1000 ? value : value * 100;
  if (value is double) return (value * 100).round();
  if (value is String) {
    final parsed = num.tryParse(value.trim());
    if (parsed == null) return 0;
    if (value.contains('.')) return (parsed * 100).round();
    return parsed >= 1000 ? parsed.round() : (parsed * 100).round();
  }
  return 0;
}
