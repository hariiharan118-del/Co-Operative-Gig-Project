class BookingChatMessage {
  const BookingChatMessage({
    required this.id,
    required this.body,
    required this.fromUser,
    required this.sentAt,
    this.bookingId,
  });

  final String id;
  final String body;
  final bool fromUser;
  final DateTime sentAt;
  final String? bookingId;
}

bool looksLikeUuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime? _asDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

BookingChatMessage? bookingChatMessageFromJson(
  dynamic raw, {
  String? currentUserId,
}) {
  final json = _asMap(raw);
  if (json == null) return null;
  final body = _asString(json['content'] ?? json['body']);
  if (body == null) return null;
  return BookingChatMessage(
    id: _asString(json['id']) ?? '',
    body: body,
    fromUser: _asString(json['senderId']) == currentUserId,
    sentAt: _asDate(json['createdAt']) ?? DateTime.now(),
    bookingId: _asString(json['bookingId']),
  );
}

List<BookingChatMessage> bookingChatMessagesFromResponse(
  dynamic raw, {
  String? currentUserId,
}) {
  final list = switch (raw) {
    List items => items,
    Map map when map['items'] is List => map['items'] as List,
    Map map when map['messages'] is List => map['messages'] as List,
    _ => const [],
  };
  return [
    for (final item in list)
      if (bookingChatMessageFromJson(item, currentUserId: currentUserId)
          case final message?)
        message,
  ];
}
