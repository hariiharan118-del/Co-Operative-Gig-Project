import 'package:easy_localization/easy_localization.dart';

import '../../booking/domain/models.dart';

final mockHistory = <Booking>[
  Booking(
    id: 'bkg_1003',
    categoryName: 'Electrician',
    address: const SavedAddress(
      id: 'addr_home',
      label: 'Home',
      line1: '12 MG Road, Shivajinagar',
      city: 'Bengaluru',
      pincode: '560001',
    ),
    status: BookingStatus.enRoute,
    createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
    totalPaise: 34900,
    worker: const WorkerInfo(
      id: 'w_12',
      name: 'Ramesh K',
      rating: 4.8,
    ),
    notes: 'Kitchen socket sparking',
  ),
  Booking(
    id: 'bkg_1002',
    categoryName: 'Plumber',
    address: const SavedAddress(
      id: 'addr_home',
      label: 'Home',
      line1: '12 MG Road, Shivajinagar',
      city: 'Bengaluru',
      pincode: '560001',
    ),
    status: BookingStatus.completed,
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
    totalPaise: 42000,
    customerRated: true,
    worker: const WorkerInfo(
      id: 'w_8',
      name: 'Sita N',
      rating: 4.9,
    ),
  ),
  Booking(
    id: 'bkg_1001',
    categoryName: 'Carpenter',
    address: const SavedAddress(
      id: 'addr_office',
      label: 'Office',
      line1: '45 100 Feet Road, Indiranagar',
      city: 'Bengaluru',
      pincode: '560038',
    ),
    status: BookingStatus.completed,
    createdAt: DateTime.now().subtract(const Duration(days: 21)),
    totalPaise: 89000,
    customerRated: true,
    worker: const WorkerInfo(
      id: 'w_3',
      name: 'Imran P',
      rating: 4.6,
    ),
  ),
];

Booking? bookingById(String id) {
  for (final booking in mockHistory) {
    if (booking.id == id) return booking;
  }
  return null;
}

Booking? findActiveBooking(Iterable<Booking> bookings) {
  final active = bookings.where((booking) => booking.isTrackable).toList();
  if (active.isEmpty) return null;
  active.sort((a, b) {
    final byCreated = b.createdAt.compareTo(a.createdAt);
    if (byCreated != 0) return byCreated;
    return b.status.progressRank.compareTo(a.status.progressRank);
  });
  return active.first;
}

String formatPaise(int paise) {
  final rupees = paise / 100;
  return '₹${rupees.toStringAsFixed(rupees.truncateToDouble() == rupees ? 0 : 2)}';
}

String statusLabel(BookingStatus status) {
  return _statusKey(status).tr();
}

/// Labels for the live tracking sheet.
String trackingStatusLabel(BookingStatus status) {
  return _statusKey(status).tr();
}

String _statusKey(BookingStatus status) => switch (status) {
      BookingStatus.requested => 'tracking.findingWorker',
      BookingStatus.assigned => 'tracking.workerAssigned',
      BookingStatus.enRoute => 'tracking.statusEnRoute',
      BookingStatus.inProgress => 'tracking.inProgress',
      BookingStatus.awaitingPayment => 'tracking.awaitingPayment',
      BookingStatus.completed => 'tracking.completed',
      BookingStatus.cancelled => 'tracking.cancelled',
    };

String statusEmoji(BookingStatus status) => switch (status) {
      BookingStatus.requested => '⏳',
      BookingStatus.assigned => '🟡',
      BookingStatus.enRoute => '🚗',
      BookingStatus.inProgress => '🔧',
      BookingStatus.awaitingPayment => '💳',
      BookingStatus.completed => '✅',
      BookingStatus.cancelled => '🚫',
    };

Booking trackingSeed(String bookingId) {
  final existing = bookingById(bookingId);
  if (existing != null) return existing;
  final sample = mockHistory.first;
  return Booking(
    id: bookingId,
    categoryName: sample.categoryName,
    address: sample.address,
    status: BookingStatus.requested,
    createdAt: DateTime.now(),
    totalPaise: sample.totalPaise,
    notes: sample.notes,
  );
}
