import 'dart:convert';

import '../../booking/domain/models.dart';

class BookingStatusUpdate {
  const BookingStatusUpdate({
    required this.bookingId,
    this.status,
    this.worker,
    this.etaMinutes,
    this.clearWorker = false,
  });

  final String bookingId;
  final BookingStatus? status;
  final WorkerInfo? worker;
  final int? etaMinutes;
  final bool clearWorker;

  static BookingStatusUpdate? tryParse(dynamic raw) {
    final map = _asMap(raw);
    if (map == null) return null;

    final bookingId = _string(map['bookingId'] ?? map['booking_id']);
    if (bookingId == null || bookingId.isEmpty) return null;

    final status = parseBookingStatus(
      _string(map['status'] ?? map['bookingStatus'] ?? map['booking_status']),
    );

    WorkerInfo? worker;
    var clearWorker = false;
    if (map.containsKey('worker')) {
      final value = map['worker'];
      if (value == null) {
        clearWorker = true;
      } else {
        worker = _workerFrom(value);
      }
    } else {
      worker = _workerFrom({
        'id': map['workerId'] ?? map['worker_id'],
        'name': map['workerName'] ?? map['worker_name'],
        'rating': map['workerRating'] ?? map['worker_rating'] ?? map['rating'],
        'phone': map['workerPhone'] ?? map['worker_phone'] ?? map['phone'],
      });
    }

    return BookingStatusUpdate(
      bookingId: bookingId,
      status: status,
      worker: worker,
      etaMinutes: _int(map['etaMinutes'] ?? map['eta_minutes'] ?? map['eta']),
      clearWorker: clearWorker,
    );
  }
}

BookingStatus? parseBookingStatus(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final key = raw.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
  return switch (key) {
    'pending_match' ||
    'broadcasting' ||
    'requested' ||
    'finding' ||
    'finding_a_worker' ||
    'finding_worker' =>
      BookingStatus.requested,
    'accepted' ||
    'assigned' ||
    'worker_assigned' =>
      BookingStatus.assigned,
    'en_route' || 'enroute' || 'on_the_way' => BookingStatus.enRoute,
    'arrived' || 'in_progress' || 'inprogress' => BookingStatus.inProgress,
    'awaiting_payment' || 'awaitingpayment' => BookingStatus.awaitingPayment,
    'completed' => BookingStatus.completed,
    'cancelled' || 'canceled' => BookingStatus.cancelled,
    _ => null,
  };
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
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return null;
}

String? _string(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _double(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

WorkerInfo? _workerFrom(dynamic raw) {
  final map = _asMap(raw);
  if (map == null) return null;
  final id = _string(map['id'] ?? map['userId'] ?? map['user_id']);
  final name = _string(map['name'] ?? map['fullName'] ?? map['full_name']);
  if (id == null && name == null) return null;
  return WorkerInfo(
    id: id ?? 'worker',
    name: name ?? 'Worker',
    rating: _double(map['rating'] ?? map['ratingAverage'] ?? map['rating_average']) ?? 0,
    phone: _string(map['phone']) ?? '',
  );
}
