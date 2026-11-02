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

  /// Parses a raw support-message row, e.g. from the `support:message`
  /// socket event or a conversation's `messages` array.
  static ChatMessage? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final row = Map<String, dynamic>.from(raw);
    final id = '${row['id'] ?? ''}';
    if (id.isEmpty) return null;
    final sender = '${row['sender'] ?? ''}'.toUpperCase();
    return ChatMessage(
      id: id,
      body: '${row['content'] ?? row['body'] ?? ''}',
      fromUser: sender == 'USER',
      sentAt: DateTime.tryParse('${row['createdAt'] ?? ''}') ?? DateTime.now(),
    );
  }

  static String? conversationIdOf(dynamic raw) {
    if (raw is! Map) return null;
    final id = raw['conversationId'] ?? raw['conversation_id'];
    if (id == null) return null;
    final value = '$id';
    return value.isEmpty ? null : value;
  }
}
