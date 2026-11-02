class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.line1,
    required this.city,
    required this.pincode,
    this.state = 'Karnataka',
    this.lat = 12.9716,
    this.lng = 77.5946,
  });

  final String id;
  final String label;
  final String line1;
  final String city;
  final String state;
  final String pincode;
  final double lat;
  final double lng;

  String get fullLine => '$line1, $city $pincode';

  SavedAddress copyWith({
    String? id,
    String? label,
    String? line1,
    String? city,
    String? state,
    String? pincode,
    double? lat,
    double? lng,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      line1: line1 ?? this.line1,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}

enum BookingTiming { instant, scheduled }

class BookingDraft {
  const BookingDraft({
    this.categoryId,
    this.categoryName,
    this.basePricePaise,
    this.address,
    this.timing = BookingTiming.instant,
    this.scheduledAt,
    this.notes = '',
  });

  final String? categoryId;
  final String? categoryName;
  final int? basePricePaise;
  final SavedAddress? address;
  final BookingTiming timing;
  final DateTime? scheduledAt;
  final String notes;

  int get estimatedPricePaise {
    final base = basePricePaise ?? 0;
    return timing == BookingTiming.instant ? base + 5000 : base;
  }

  BookingDraft copyWith({
    String? categoryId,
    String? categoryName,
    int? basePricePaise,
    SavedAddress? address,
    BookingTiming? timing,
    DateTime? scheduledAt,
    String? notes,
    bool clearSchedule = false,
  }) {
    return BookingDraft(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      basePricePaise: basePricePaise ?? this.basePricePaise,
      address: address ?? this.address,
      timing: timing ?? this.timing,
      scheduledAt: clearSchedule ? null : (scheduledAt ?? this.scheduledAt),
      notes: notes ?? this.notes,
    );
  }
}

enum BookingStatus {
  requested,
  assigned,
  enRoute,
  inProgress,
  awaitingPayment,
  completed,
  cancelled,
}

extension BookingStatusX on BookingStatus {
  bool get isTrackable =>
      this == BookingStatus.requested ||
      this == BookingStatus.assigned ||
      this == BookingStatus.enRoute ||
      this == BookingStatus.inProgress ||
      this == BookingStatus.awaitingPayment;

  int get progressRank => switch (this) {
        BookingStatus.cancelled => -1,
        BookingStatus.requested => 0,
        BookingStatus.assigned => 1,
        BookingStatus.enRoute => 2,
        BookingStatus.inProgress => 3,
        BookingStatus.awaitingPayment => 4,
        BookingStatus.completed => 5,
      };
}

class WorkerInfo {
  const WorkerInfo({
    required this.id,
    required this.name,
    required this.rating,
    this.phone = '+919876543210',
  });

  final String id;
  final String name;
  final double rating;
  final String phone;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  WorkerInfo copyWith({
    String? id,
    String? name,
    double? rating,
    String? phone,
  }) {
    return WorkerInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      phone: phone ?? this.phone,
    );
  }
}

class Booking {
  const Booking({
    required this.id,
    required this.categoryName,
    required this.address,
    required this.status,
    required this.createdAt,
    required this.totalPaise,
    this.scheduledAt,
    this.worker,
    this.notes,
    this.messages = const [],
    this.customerRated = false,
  });

  final String id;
  final String categoryName;
  final SavedAddress address;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final int totalPaise;
  final WorkerInfo? worker;
  final String? notes;
  final List<ChatMessage> messages;
  final bool customerRated;

  bool get canCancel =>
      status == BookingStatus.requested ||
      status == BookingStatus.assigned ||
      status == BookingStatus.enRoute;

  bool get isTrackable => status.isTrackable;

  /// Live tracking, or the post-job settle screen while payment is pending.
  String get livePath => status == BookingStatus.awaitingPayment
      ? '/booking/$id/settle'
      : '/tracking/$id';

  Booking copyWith({
    String? id,
    String? categoryName,
    SavedAddress? address,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? scheduledAt,
    int? totalPaise,
    WorkerInfo? worker,
    String? notes,
    List<ChatMessage>? messages,
    bool? customerRated,
    bool clearWorker = false,
  }) {
    return Booking(
      id: id ?? this.id,
      categoryName: categoryName ?? this.categoryName,
      address: address ?? this.address,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      totalPaise: totalPaise ?? this.totalPaise,
      worker: clearWorker ? null : (worker ?? this.worker),
      notes: notes ?? this.notes,
      messages: messages ?? this.messages,
      customerRated: customerRated ?? this.customerRated,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.body,
    required this.fromUser,
    required this.sentAt,
  });

  final String id;
  final String body;
  final bool fromUser;
  final DateTime sentAt;
}

class CallInitiateResult {
  const CallInitiateResult({
    required this.masked,
    this.phoneNumber,
  });

  final bool masked;
  final String? phoneNumber;
}

class RazorpayCheckoutResult {
  const RazorpayCheckoutResult({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });

  final String paymentId;
  final String orderId;
  final String signature;
}

class PaymentReceipt {
  const PaymentReceipt({
    required this.id,
    required this.bookingId,
    required this.receiptNo,
    required this.amountPaise,
    required this.status,
    this.categoryName,
    this.currency = 'INR',
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.invoiceUrl,
    this.paidAt,
  });

  final String id;
  final String bookingId;
  final String receiptNo;
  final String? categoryName;
  final int amountPaise;
  final String currency;
  final String status;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? invoiceUrl;
  final DateTime? paidAt;

  bool get isPaid => status.toUpperCase() == 'CAPTURED';
}

class PaymentOrder {
  const PaymentOrder({
    required this.orderId,
    required this.keyId,
    required this.amountPaise,
    this.bookingId = '',
    this.currency = 'INR',
    this.alreadyPaid = false,
    this.receipt,
  });

  final String bookingId;
  final String orderId;
  final String keyId;
  final int amountPaise;
  final String currency;
  final bool alreadyPaid;
  final PaymentReceipt? receipt;
}

class UserProfile {
  const UserProfile({
    this.id = '',
    required this.name,
    required this.phone,
    this.email = '',
  });

  final String id;
  final String name;
  final String phone;
  final String email;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  UserProfile copyWith({String? id, String? name, String? phone, String? email}) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }
}
