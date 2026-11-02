import '../../tracking/data/booking_status_event.dart';
import '../domain/models.dart';

Map<String, dynamic>? asJsonMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

String? asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

double asDouble(dynamic value, [double fallback = 0]) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int rupeesToPaise(dynamic value) {
  if (value is int) return value * 100;
  if (value is num) return (value * 100).round();
  if (value is String) {
    final parsed = num.tryParse(value);
    if (parsed == null) return 0;
    return (parsed * 100).round();
  }
  return 0;
}

DateTime? asDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

SavedAddress addressFromJson(Map<String, dynamic> json) {
  return SavedAddress(
    id: asString(json['id']) ?? '',
    label: asString(json['label']) ?? 'Address',
    line1: asString(json['line1']) ?? '',
    city: asString(json['city']) ?? '',
    state: asString(json['state']) ?? 'Karnataka',
    pincode: asString(json['pincode']) ?? '',
    lat: asDouble(json['lat'], 12.9716),
    lng: asDouble(json['lng'], 77.5946),
  );
}

WorkerInfo? workerFromBookingJson(Map<String, dynamic> json) {
  final nested = asJsonMap(json['worker']);
  final profile = asJsonMap(nested?['workerProfile']);
  final id = asString(
    nested?['id'] ?? nested?['userId'] ?? json['workerId'] ?? json['worker_id'],
  );
  final name = asString(
    profile?['name'] ??
        nested?['name'] ??
        json['workerName'] ??
        json['worker_name'],
  );
  if (id == null && name == null) return null;
  return WorkerInfo(
    id: id ?? 'worker',
    name: name ?? 'Worker',
    rating: asDouble(
      profile?['ratingAverage'] ?? nested?['rating'] ?? json['workerRating'],
    ),
    phone: asString(nested?['phone'] ?? json['workerPhone']) ?? '',
  );
}

List<ChatMessage> chatFromBookingJson(
  Map<String, dynamic> json, {
  String? currentUserId,
}) {
  return chatMessagesFromResponse(
    json['chatMessages'] ?? json['messages'],
    currentUserId: currentUserId,
  );
}

List<ChatMessage> chatMessagesFromResponse(
  dynamic raw, {
  String? currentUserId,
}) {
  var value = raw;
  final map = asJsonMap(raw);
  if (map != null) {
    value = map['items'] ?? map['messages'] ?? map['chatMessages'] ?? raw;
  }
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (asJsonMap(item) != null)
        chatMessageFromJson(asJsonMap(item)!, currentUserId: currentUserId),
  ];
}

ChatMessage chatMessageFromJson(
  Map<String, dynamic> json, {
  String? currentUserId,
}) {
  return ChatMessage(
    id: asString(json['id']) ?? '',
    body: asString(json['content'] ?? json['body']) ?? '',
    fromUser: asString(json['senderId']) == currentUserId,
    sentAt: asDate(json['createdAt']) ?? DateTime.now(),
  );
}

Booking bookingFromJson(
  Map<String, dynamic> json, {
  String? currentUserId,
}) {
  final category = asJsonMap(json['serviceCategory']) ?? const {};
  final addressJson = asJsonMap(json['address']);
  final payment = asJsonMap(json['payment']);
  final status = parseBookingStatus(asString(json['status'])) ?? BookingStatus.requested;
  return Booking(
    id: asString(json['id']) ?? '',
    categoryName: asString(category['name']) ?? 'Service',
    address: addressJson == null
        ? const SavedAddress(
            id: '',
            label: 'Address',
            line1: '',
            city: '',
            pincode: '',
          )
        : addressFromJson(addressJson),
    status: status,
    createdAt: asDate(json['createdAt']) ?? DateTime.now(),
    scheduledAt: asDate(json['scheduledAt']),
    totalPaise: rupeesToPaise(payment?['amount'] ?? category['basePricing']),
    worker: workerFromBookingJson(json),
    notes: asString(json['cancelReason']),
    messages: chatFromBookingJson(json, currentUserId: currentUserId),
    customerRated: customerRatedFromJson(json),
  );
}

bool customerRatedFromJson(Map<String, dynamic> json) {
  if (json['customerRated'] == true || json['rated'] == true) return true;
  final reviews = json['reviews'];
  if (reviews is! List) return false;
  for (final item in reviews) {
    final map = asJsonMap(item);
    if (map == null) continue;
    final direction = asString(map['direction'])?.toUpperCase();
    if (direction == 'CUSTOMER_TO_WORKER') return true;
  }
  return false;
}

int _asPaise(dynamic amountPaise, dynamic amountRupees) {
  if (amountPaise is int) return amountPaise;
  if (amountPaise is num) return amountPaise.round();
  return rupeesToPaise(amountRupees);
}

PaymentReceipt paymentReceiptFromJson(Map<String, dynamic> json) {
  final nested = asJsonMap(json['receipt']);
  final src = nested ?? json;
  final bookingId = asString(src['bookingId']) ?? '';
  return PaymentReceipt(
    id: asString(src['id']) ?? '',
    bookingId: bookingId,
    receiptNo: asString(src['receiptNo']) ??
        (bookingId.isEmpty
            ? 'INV'
            : 'INV-${bookingId.replaceAll('-', '').toUpperCase()}'),
    categoryName: asString(src['categoryName']),
    amountPaise: _asPaise(src['amountPaise'], src['amount']),
    currency: asString(src['currency']) ?? 'INR',
    status: asString(src['status']) ?? 'PENDING',
    razorpayOrderId: asString(src['razorpayOrderId']),
    razorpayPaymentId: asString(src['razorpayPaymentId']),
    invoiceUrl: asString(src['invoiceUrl']),
    paidAt: asDate(src['paidAt']),
  );
}

PaymentOrder paymentOrderFromJson(Map<String, dynamic> json) {
  final receiptJson = asJsonMap(json['receipt']);
  return PaymentOrder(
    bookingId: asString(json['bookingId']) ?? '',
    orderId: asString(json['orderId'] ?? json['razorpayOrderId']) ?? '',
    keyId: asString(json['keyId'] ?? json['key']) ?? '',
    amountPaise: _asPaise(json['amountPaise'], json['amount']),
    currency: asString(json['currency']) ?? 'INR',
    alreadyPaid: json['alreadyPaid'] == true,
    receipt: receiptJson == null ? null : paymentReceiptFromJson(receiptJson),
  );
}

CallInitiateResult callInitiateResultFromJson(Map<String, dynamic> json) {
  return CallInitiateResult(
    masked: json['masked'] == true,
    phoneNumber: asString(json['phoneNumber'] ?? json['phone']),
  );
}

ChatMessage chatMessageFromSocket(dynamic raw, {String? currentUserId}) {
  final json = asJsonMap(raw) ?? const {};
  return chatMessageFromJson(json, currentUserId: currentUserId);
}
